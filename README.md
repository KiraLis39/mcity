# Сервис управления УЗ

Подробное
описание: ****[АТР Бизнес 010. Регистрация - Авторизация - Проверка по ИНН](https://itpm-wiki.mos.ru/pages/viewpage.action?pageId=161798072)****

Swagger - документация находится [здесь](https://api-docs.dev01.russpass.dev/business/partners/swagger-ui/index.html) .

## Запуск приложения локально

- Для локального запуска потребуются следующие компоненты:
    - `postgresql`
    - `redis`

Их можно запустить в Docker при помощи docker-compose.yaml файла:

```yaml
version: "3.8"

networks:
  widget-network:
    driver: bridge

services:
  keycloak:
    image: jboss/keycloak
    container_name: keycloak
    ports:
      - 8886:8080
    environment:
      - KEYCLOAK_USER=admin
      - KEYCLOAK_PASSWORD=1234
    networks:
      - widget-network

  db-postgres:
    image: postgres:12
    container_name: db-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=test_db
    networks:
      - widget-network

  cache:
    image: redis:6.2-alpine
    container_name: cache
    restart: always
    ports:
      - '6379:6379'
    networks:
      - widget-network
```

Командой:

```bash
 docker-compose up -d
```

## Конфигурации расположены в папке resource:

![properties](info/properties.png)

- в application.yml - находятся общие конфиги для локального пользования и для dev - контура (значения передаются по
  ссылкам(dev-контур) и дефолтными(локальная разработка))
- в application-prod.yml - находятся конфигурации для использования в production среде (все значения передаются только
  ссылками)

Для локальной разработки достаточно указать в дефолтные параметры, параметры запускаемых систем из docker-compose.yml
файла + дополнительные параметры, которые задаются при настройке keycloak + интеграционное взаимодействие.

## Про доп. параметры:

Для подключения к keycloak необходимы следующие зависимости:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${JWT_ISSUE_URI:https://idm.dev01.russpass.dev/sso/realms/dev-b2b-realm}
          jwk-set-uri: ${JWT_JWK_URI:https://idm.dev01.russpass.dev/sso/realms/dev-b2b-realm/protocol/openid-connect/certs}
keycloak:
  auth-server-url: ${KEYCLOAK_SERVER_URL:https://idm.dev01.russpass.dev/sso}
  realm: ${KEYCLOAK_REALM:dev-b2b-realm}
  resource: ${KEYCLOAK_SERVICE:auth-service}
  bearer-only: false
  use-resource-role-mappings: true
  credentials:
    secret: ${KEYCLOAK_SECRET_SERVICE:11b0720d-8b7e-4daa-86b4-3b234a8ff712}
```

Соответственно имя реалма, урл сервера, сам сервис - вы создаете руками (если рассматривать keycloak из docker-compose.
secret - получается в случае если мы сам сервис делаем не публичным)

**Для модерирования** (регистрации пользователя, выдачи ему базовых ролей необходимо создать и настроить юзера, который
будет этим заниматься(мы создавали его в кейклок с именем admin и паролем 1234, с полными правами)):

```yaml
app:
  keycloak:
    admin:
      name: ${KEYCLOAK_ADMIN_NAME:admin}
      password: ${KEYCLOAK_ADMIN_PASSWORD:1234}
      master-realm: ${KEYCLOAK_REALM:dev-b2b-realm}
      client: ${KEYCLOAK_SERVICE:auth-service}
      secret: ${KEYCLOAK_SECRET_SERVICE:11b0720d-8b7e-4daa-86b4-3b234a8ff712}
```

**ВАЖНО!**

Без данного пользователя - система не сможет производить взаимодействие со стороной keycloak!

### **Все интеграционные взаимодействия идут также через property:**

```yaml
app:
  props:
    storage:
      grant-type: ${STORAGE_GRANT_TYPE:password}
      client-id: ${STORAGE_CLIENT_ID:russpass}
      scope: ${STORAGE_SCOPE:read write}
      secret: ${STORAGE_SECRET:secret}
      username: ${STORAGE_USER_NAME:admin@admin.com}
      password: ${STORAGE_USER_PASSWORD:123}
      authorization: ${STORAGE_AUTHORIZATION:"Basic cnVzc3Bhc3M6c2VjcmV0"}
      token-url: ${STORAGE_TOKEN_URL:https://api.dev01.russpass.dev/sso/oauth/token}
      url: ${STORAGE_URL:https://api.dev01.russpass.dev/attach/file}
    crm:
      access_token: ${CRM_ACCESS_TOKEN:7d5cecf7-e91c-4424-9bc9-c062eeb42259}
      partner_path: ${PARTNER_CRM_PATH:https://api.dev01.russpass.dev/crm/business/partner}
      partner_update_path: ${UPDATE_CRM_PATH:https://api.dev01.russpass.dev/crm/business/update_partner}
      partner_list_path: ${LIST_CRM_PATH:https://api.dev01.russpass.dev/crm/business/partner_list}
      partner_create_path: ${CREATE_CRM_PATH:https://api.dev01.russpass.dev/crm/business/create_partner}
    keycloak:
      base-role: ${KEYCLOAK_BASE_ROLE:Partner_Business_Lite}
    mail:
      url: ${MAIL_URL:https://api.russpass.ru/notification-email/input/send}
      api-key: ${MAIL_API_KEY:9ff57f7e-fd0f-4931-9f56-3c435a9b5ff5}
```

На данном этапе блок **storage** отвечает за интеграцию
с [attach](https://itpm-wiki.mos.ru/pages/viewpage.action?pageId=61621300)  сервисом(хранение файлов).

Блок **crm** - c [crm](https://itpm-wiki.mos.ru/pages/viewpage.action?pageId=166053165) сервисом.
Также есть взаимодействия с
сервисом [мэил уведомлений](https://itpm-wiki.mos.ru/pages/viewpage.action?pageId=127254992)  (блок **mail**).

В блоке **keycloak** описана базовая роль , которая выдается при регистрации.

При запуске в продакшн - все дефолтные значения исключены, допустимы только значения по ссылкам, что можно наблюдать в
конфигурации application-prod.yml.

Для переключения профилей необходимо воспользоваться editConfiguration - > Active Profile , и указать необходимый. При
билде и отправке на стенд нужный профиль необходимо выбрать в настройках pom.xml (spring:profiles:active: <Ваш профиль>)
.

### **Общее взаимодействие сервиса представлено на схеме ниже:**

![Архитектура v6-Регистрация.jpg](info/schema.jpg)
