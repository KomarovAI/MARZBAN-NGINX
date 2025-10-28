# MARZBAN + NGINX 🚀

Комплексное решение для развертывания панели управления VPN Marzban с обратным прокси Nginx, SSL-сертификатами Let's Encrypt и автоматической конфигурацией VLESS Reality.

## 📋 Возможности

- ✅ **Marzban VPN панель** с веб-интерфейсом
- ✅ **MySQL база данных** с ультра-оптимизацией памяти
- ✅ **Nginx обратный прокси** с SSL терминацией
- ✅ **Автоматические SSL сертификаты** через Certbot
- ✅ **VLESS Reality на нестандартных портах** (2053, 2083, 2087)
- ✅ **Автоматическая генерация ключей** Reality
- ✅ **Готовые клиентские конфигурации**
- ✅ **Оптимизированная безопасность** для России
- ✅ **Ультра-экономное потребление RAM** (~200MB общее)

## 🔧 Конфигурация

### Доменное имя
**Домен:** `botinger789298.work.gd`  
**IP:** `31.59.58.96`

### Порты
- ~~**80/443** - HTTP/HTTPS (Nginx)~~ — отключено по запросу, эти порты обслуживает внешний Nginx с сайтом
- **8080** - Панель Marzban (HTTPS)
- **2053** - VLESS Reality (Google)
- **2083** - VLESS Reality (Microsoft)
- **2087** - VLESS Reality (Cloudflare)
- **3306** - MySQL (локальный)

### Учетные данные
- **Пользователь:** `artur789298`
- **Пароль:** `WARpteN789298`
- **Email:** `artur.komarovv@gmail.com`

## 💾 Требования к ресурсам

### Минимальные требования:
- **RAM:** 512MB (рекомендуется 1GB)
- **CPU:** 1 vCore
- **Диск:** 2GB свободного места
- **Сеть:** 1Mbps (для небольшой нагрузки)

### Оптимизированное потребление:
- **MySQL:** ~80MB RAM (вместо 300-500MB)
- **Marzban:** ~110MB RAM
- **Nginx:** ~5MB RAM
- **Certbot:** ~1MB RAM
- **Общее:** ~200MB RAM (экономия 75%)

## 🚀 Быстрый старт

### 1. Клонирование репозитория
```bash
git clone https://github.com/KomarovAI/MARZBAN-NGINX.git
cd MARZBAN-NGINX
```

### 2. Проверка конфигурации
Убедитесь, что домен `botinger789298.work.gd` указывает на IP `31.59.58.96`:
```bash
dig botinger789298.work.gd
```

### 3. Установка зависимостей
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose-plugin curl openssl

# CentOS/RHEL
sudo yum install docker docker-compose curl openssl

# Запуск Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### 4. Развертывание
```bash
# Делаем скрипт исполняемым
chmod +x scripts/deploy.sh

# Запускаем полное развертывание
./scripts/deploy.sh
```

### 5. Ручная настройка (если нужно)
```bash
# Только SSL сертификаты (standalone, т.к. порт 80 занят внешним Nginx)
chmod +x scripts/init-ssl.sh
./scripts/init-ssl.sh

# Только генерация VLESS ключей
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

## 📁 Структура проекта

```
MARZBAN-NGINX/
├── docker-compose.yml          # Основная конфигурация Docker Compose (оптимизированная)
├── .env                        # Переменные окружения с оптимизацией
├── mysql-ultra-minimal.conf    # Ультра-минимальная конфигурация MySQL 8.0
├── xray_config.json           # Конфигурация Xray с VLESS Reality
├── nginx/
│   ├── nginx.conf             # Основная конфигурация Nginx
│   └── conf.d/
│       └── marzban.conf       # Конфигурация сервера Marzban (без 80/443)
├── scripts/
│   ├── deploy.sh              # Полный скрипт развертывания
│   ├── init-ssl.sh            # Инициализация SSL (standalone)
│   └── generate-keys.sh       # Генерация VLESS Reality ключей
├── certbot/                   # SSL сертификаты (создается автоматически)
└── vless_client_config.json   # Шаблон клиентской конфигурации (создается автоматически)
```

## ⚡ Оптимизация памяти

### MySQL оптимизация
Используется специальный конфиг `mysql-ultra-minimal.conf`:
- `innodb_buffer_pool_size = 32M` (вместо 128M+)
- `performance_schema = OFF` (экономит ~400MB)
- `max_connections = 10` (для небольшой нагрузки)
- Отключены лишние модули и буферы

### Marzban оптимизация
- `UVICORN_WORKERS=1` (один процесс)
- `SQLALCHEMY_POOL_SIZE=3` (минимум соединений)
- Увеличенные интервалы заданий
- Отключено подробное логирование

### Docker ресурсные лимиты
- MySQL: лимит 256MB RAM
- Marzban: лимит 512MB RAM
- Nginx: лимит 64MB RAM
- Certbot: лимит 64MB RAM

## 🔐 VLESS Reality конфигурация

### Серверные порты
1. **Порт 2053** - Google Reality (`www.google.com`)
2. **Порт 2083** - Microsoft Reality (`www.microsoft.com`)
3. **Порт 2087** - Cloudflare Reality (`www.cloudflare.com`)

### Автоматическая генерация ключей
Скрипт `generate-keys.sh` автоматически:
- Генерирует X25519 ключи (private/public)
- Создает случайные Short IDs
- Обновляет конфигурацию Xray
- Создает шаблон клиентской конфигурации

### Клиентская конфигурация
После выполнения скриптов создается файл `vless_client_config.json` с готовой конфигурацией для клиентов. Необходимо только заменить `USER_UUID_HERE` на реальный UUID пользователя из панели Marzban.

## 🔧 Управление

### Основные команды
```bash
# Просмотр логов
docker compose logs -f

# Перезапуск сервисов
docker compose restart

# Обновление образов
docker compose pull && docker compose up -d

# Остановка всех сервисов
docker compose down

# Полная очистка (с данными)
docker compose down -v
```

### Проверка статуса
```bash
# Статус контейнеров
docker compose ps

# Использование ресурсов (оптимизированное)
docker stats

# Проверка SSL сертификата
curl -I https://botinger789298.work.gd:8080

# Тест VLESS портов
telnet botinger789298.work.gd 2053
```

## 📊 Мониторинг

### Логи
- **Nginx:** `docker compose logs nginx`
- **Marzban:** `docker compose logs marzban`
- **MySQL:** `docker compose logs mysql`
- **Certbot:** `docker compose logs certbot`

### Важные файлы
- SSL сертификаты: `./certbot/conf/live/botinger789298.work.gd/`
- Данные Marzban: `/var/lib/marzban/`
- База данных MySQL: `/var/lib/marzban/mysql/`
- Конфигурация MySQL: `./mysql-ultra-minimal.conf`

## 🔒 Безопасность

### SSL/TLS
- HTTP→HTTPS редирект теперь делается внешним Nginx (80/443 убраны)
- Современные шифры TLS 1.2/1.3
- HSTS заголовки
- OCSP Stapling

### VLESS Reality
- Маскировка под легитимные сайты
- Устойчивость к DPI блокировкам
- Множественные домены маскировки
- Случайные Short IDs для дополнительной безопасности

### Сетевая безопасность
- Изолированная Docker сеть
- Блокировка приватных IP
- Фильтрация рекламы на уровне маршрутизации
- Скрытие версий серверного ПО

## 🛠️ Настройка переменных окружения

Основные переменные в `.env`:

```bash
# Домен и SSL
DOMAIN=botinger789298.work.gd
SSL_EMAIL=artur.komarovv@gmail.com
SERVER_IP=31.59.58.96

# Учетные данные Marzban
SUDO_USERNAME=artur789298
SUDO_PASSWORD=WARpteN789298

# База данных
MYSQL_ROOT_PASSWORD=WARpteN789298_root
MYSQL_PASSWORD=WARpteN789298

# SSL для внешнего доступа (важно!)
UVICORN_SSL_CERTFILE=/etc/letsencrypt/live/botinger789298.work.gd/fullchain.pem
UVICORN_SSL_KEYFILE=/etc/letsencrypt/live/botinger789298.work.gd/privkey.pem

# Ультра-оптимизация памяти
SQLALCHEMY_POOL_SIZE=3
SQLALCHEMY_MAX_OVERFLOW=5
UVICORN_WORKERS=1
UVICORN_ACCESS_LOG=false
```

## 📱 Доступ к панели

**URL:** https://botinger789298.work.gd:8080/dashboard/

**Учетные данные:**
- Пользователь: `artur789298`
- Пароль: `WARpteN789298`

## ❓ Устранение неполадок

### 🚨 502 Bad Gateway при доступе к панели

**Причина:** Marzban с версии 0.7.0 по умолчанию привязывается только к localhost без SSL сертификатов.

**Решение:**
1. Убедитесь, что в `.env` присутствуют переменные SSL:
   ```bash
   UVICORN_SSL_CERTFILE=/etc/letsencrypt/live/botinger789298.work.gd/fullchain.pem
   UVICORN_SSL_KEYFILE=/etc/letsencrypt/live/botinger789298.work.gd/privkey.pem
   ```

2. Проверьте, что SSL сертификаты монтируются в контейнер Marzban:
   ```bash
   # В docker-compose.yml должен быть volume:
   - ./certbot/conf:/etc/letsencrypt:ro
   ```

3. Убедитесь, что nginx проксирует на HTTPS:
   ```bash
   # В nginx/conf.d/marzban.conf должно быть:
   proxy_pass https://marzban:8000;
   proxy_ssl_verify off;
   ```

4. Проверьте логи Marzban - должно быть:
   ```bash
   docker compose logs marzban | grep "Uvicorn running"
   # Ожидаемый результат: "Uvicorn running on https://0.0.0.0:8000"
   ```

### 🔧 MySQL падает при запуске

**Причина:** Устаревшие параметры конфигурации для MySQL 8.0.

**Решение:**
1. Убедитесь, что используется `mysql-ultra-minimal.conf`:
   ```bash
   # Не должно быть query_cache_size - удалено в MySQL 8.0
   grep -v "query_cache_size" mysql-ultra-minimal.conf
   ```

2. Проверьте логи MySQL:
   ```bash
   docker compose logs mysql
   # Не должно быть ошибок "unknown variable"
   ```

### 💾 Высокое потребление памяти

**Проблема:** Контейнеры потребляют больше ожидаемого.

**Решение:**
1. Проверьте лимиты ресурсов:
   ```bash
   docker stats --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"
   ```

2. Убедитесь, что MySQL использует минимальную конфигурацию:
   ```bash
   docker compose exec mysql mysql -uroot -pWARpteN789298_root -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
   # Должно быть 33554432 (32MB)
   ```

3. Перезапустите с оптимизированными лимитами:
   ```bash
   docker compose down && docker compose up -d
   ```

### Проблемы с SSL
```bash
# Проверка DNS
dig botinger789298.work.gd

# Повторная генерация сертификатов (standalone)
./scripts/init-ssl.sh

# Проверка Nginx конфигурации
docker compose exec nginx nginx -t
```

### Проблемы с VLESS Reality
```bash
# Перегенерация ключей
./scripts/generate-keys.sh

# Проверка Xray конфигурации
docker compose exec marzban xray -test -config /usr/local/share/xray/xray_config.json
```

### Проблемы с базой данных
```bash
# Подключение к MySQL
docker compose exec mysql mysql -uroot -pWARpteN789298_root

# Создание бекапа
docker compose exec mysql mysqldump -uroot -pWARpteN789298_root marzban > backup.sql
```

### Конфликт портов при развертывании

**Проблема:** Порты 80/443 заняты другими сервисами.

**Решение:**
```bash
# Найдите и остановите конфликтующие контейнеры
docker ps | grep -E ":80|:443"
docker stop CONTAINER_NAME

# Или временно остановите внешний nginx
sudo systemctl stop nginx

# После развертывания Marzban можете запустить обратно
sudo systemctl start nginx
```

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте логи: `docker compose logs`
2. Убедитесь, что домен указывает на правильный IP
3. Проверьте, что порты открыты в файрволе
4. Создайте Issue в репозитории с описанием проблемы

## 📈 Производительность

### Рекомендации по масштабированию:
- **До 50 пользователей:** текущая конфигурация идеальна
- **50-100 пользователей:** увеличьте лимиты MySQL до 512MB
- **100+ пользователей:** рассмотрите переход на PostgreSQL

### Мониторинг ресурсов:
```bash
# Постоянный мониторинг
docker stats

# Проверка использования диска
docker system df

# Очистка неиспользуемых ресурсов
docker system prune -f
```

## 📄 Лицензия

MIT License - можете использовать для любых целей.

---

**Создано для безопасного доступа к интернету в России** 🇷🇺  
**Оптимизировано для минимального потребления ресурсов** ⚡