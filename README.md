# MARZBAN + NGINX 🚀

Комплексное решение для развертывания панели управления VPN Marzban с обратным прокси Nginx, SSL-сертификатами Let's Encrypt и автоматической конфигурацией VLESS Reality.

## 📋 Возможности

- ✅ **Marzban VPN панель** с веб-интерфейсом
- ✅ **MySQL база данных** для хранения данных
- ✅ **Nginx обратный прокси** с SSL терминацией
- ✅ **Автоматические SSL сертификаты** через Certbot
- ✅ **VLESS Reality на нестандартных портах** (2053, 2083, 2087)
- ✅ **Автоматическая генерация ключей** Reality
- ✅ **Готовые клиентские конфигурации**
- ✅ **Оптимизированная безопасность** для России

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
├── docker-compose.yml          # Основная конфигурация Docker Compose
├── .env                        # Переменные окружения
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

# Использование ресурсов
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

# Оптимизация производительности
SQLALCHEMY_POOL_SIZE=10
SQLALCHEMY_MAX_OVERFLOW=30
```

## 📱 Доступ к панели

**URL:** https://botinger789298.work.gd:8080

**Учетные данные:**
- Пользователь: `artur789298`
- Пароль: `WARpteN789298`

## ❓ Устранение неполадок

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

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте логи: `docker compose logs`
2. Убедитесь, что домен указывает на правильный IP
3. Проверьте, что порты открыты в файрволе
4. Создайте Issue в репозитории с описанием проблемы

## 📄 Лицензия

MIT License - можете использовать для любых целей.

---

**Создано для безопасного доступа к интернету в России** 🇷🇺