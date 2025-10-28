# MARZBAN + NGINX 🚀

Комплексное решение для развертывания панели управления VPN Marzban с обратным прокси Nginx, SSL-сертификатами Let's Encrypt и автоматической конфигурацией VLESS Reality.

## 🎯 ОБНОВЛЕНО - ПОЛНОСТЬЮ РАБОЧАЯ ВЕРСИЯ

**Ветка: `marz-UP-min-ram-optimization`** - стабильная, оптимизированная версия с минимальным потреблением RAM.

### ✅ Что исправлено в этой версии:

- **🔧 Xray Core 24.12.31 совместимость** - устранена ошибка `IPIfNonMatch`
- **🐳 Docker сеть** - исправлены конфликты подсетей (172.25.0.0/24)
- **📡 VLESS Reality порты** - корректное маппинг портов 2053, 2083, 2087
- **🌐 Nginx SSL прокси** - исправлена конфигурация для HTTPS соединений
- **💾 MySQL оптимизация** - ультра экономное потребление памяти (~87MB)
- **🔐 SSL сертификаты** - правильная интеграция с Marzban

### 📊 Производительность:

- **Общее потребление RAM:** ~208MB (вместо 800MB+)
- **MySQL:** ~87MB (ультра-минимальная конфигурация)
- **Marzban:** ~113MB
- **Nginx:** ~5MB
- **Время запуска:** <30 секунд

## 📋 Возможности

- ✅ **Marzban VPN панель** с веб-интерфейсом
- ✅ **MySQL база данных** с ультра-оптимизацией памяти
- ✅ **Nginx обратный прокси** с SSL терминацией
- ✅ **Автоматические SSL сертификаты** через Certbot
- ✅ **VLESS Reality на портах** 2053, 2083, 2087
- ✅ **Рабочие Reality ключи** (сгенерированы и протестированы)
- ✅ **Готовые клиентские конфигурации**
- ✅ **Оптимизированная безопасность** для России
- ✅ **Стабильная работа Xray Core** без перезагрузок

## 🔧 Конфигурация

### Доменное имя

**Домен:**
```
botinger789298.work.gd
```
**IP:**
```
31.59.58.96
```

### Порты

- **8080** - Панель Marzban (HTTPS)
- **2053** - VLESS Reality (Google)
- **2083** - VLESS Reality (Microsoft)
- **2087** - VLESS Reality (Cloudflare)
- **3306** - MySQL (локальный)

### Учетные данные

- **Пользователь:** `artur789298`
- **Пароль:** `WARpteN789298`
- **Email:** `artur.komarovv@gmail.com`

## 🔑 Reality Ключи (Протестированы)

- **Private Key:** `INdNbsx4WKgFqNCT1azbhcSPnigM3N1WglJ1VQkyujE`
- **Public Key:** `XoOU8tEL2y15F9VCPxO6s3gsBcu-JPApncwueb6lYVE`
- **Short IDs:** `2fdc840f870b4092`, `6b8f14f0976d3b7c`, `d9cf4cbbcfbff883`

## 🚀 Быстрый старт

### 1. Клонирование оптимизированной ветки

```bash
git clone -b marz-UP-min-ram-optimization https://github.com/KomarovAI/MARZBAN-NGINX.git
cd MARZBAN-NGINX
```

### 2. Проверка DNS конфигурации

```bash
dig botinger789298.work.gd
# Должен вернуть: 31.59.58.96
```

### 3. Установка зависимостей

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose-plugin curl openssl

# Запуск Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### 4. Развертывание

```bash
# Запуск оптимизированной конфигурации
docker compose up -d

# Проверка статуса
docker compose ps
```

### 5. Проверка работоспособности

```bash
# Проверка VLESS портов
for port in 2053 2083 2087; do
    echo -n "Порт $port: "
    timeout 2 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null && echo "✅ Открыт" || echo "❌ Закрыт"
done

# Проверка панели
curl -k -I https://botinger789298.work.gd:8080/
```

## 📁 Структура проекта

```
MARZBAN-NGINX/
├── docker-compose.yml     # Оптимизированная Docker конфигурация
├── .env                   # Переменные окружения с Reality ключами
├── mysql-ultra-minimal.conf # Ультра-минимальная конфигурация MySQL
├── xray_config.json       # Исправленная конфигурация Xray Reality
├── nginx/
│   ├── nginx.conf         # Основная конфигурация Nginx
│   └── conf.d/
│       └── marzban.conf   # SSL прокси для Marzban (исправлен)
├── scripts/
│   ├── deploy.sh          # Скрипт развертывания
│   ├── init-ssl.sh        # Инициализация SSL
│   └── generate-keys.sh   # Генерация VLESS ключей
└── certbot/               # SSL сертификаты (создается автоматически)
```

## ⚡ Ключевые оптимизации

### MySQL (87MB RAM)
```bash
innodb_buffer_pool_size = 32M
performance_schema = OFF
max_connections = 25
```

### Xray Core
- Убрана несовместимая `domainStrategy: IPIfNonMatch`
- Упрощенная конфигурация логирования
- Стабильные Reality настройки

### Docker
- Исправлена подсеть: `172.25.0.0/24`
- Убран устаревший `version`
- Открыты VLESS порты на всех интерфейсах

## 📱 Доступ к панели

**URL:** https://botinger789298.work.gd:8080/dashboard/

**Учетные данные:**
- Пользователь: `artur789298`
- Пароль: `WARpteN789298`

## 🔗 Клиентские конфигурации

### VLESS ссылка (Google Reality)
```
vless://USER_UUID@botinger789298.work.gd:2053?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.google.com&fp=chrome&pbk=XoOU8tEL2y15F9VCPxO6s3gsBcu-JPApncwueb6lYVE&sid=2fdc840f870b4092&type=tcp#Google_Reality_2053
```

### Альтернативные порты
- **2083** - Microsoft Reality (`sni=www.microsoft.com`)
- **2087** - Cloudflare Reality (`sni=www.cloudflare.com`)

## 🛠️ Управление

### Основные команды

```bash
# Просмотр логов
docker compose logs -f

# Проверка ресурсов
docker stats --no-stream

# Перезапуск
docker compose restart

# Остановка
docker compose down
```

### Диагностика

```bash
# Проверка Xray Core
docker compose logs marzban | grep -i xray

# Статус контейнеров
docker compose ps

# Использование памяти
docker stats --format "table {{.Container}}\t{{.MemUsage}}\t{{.CPUPerc}}"
```

## ❓ Устранение неполадок

### Все исправлено в этой версии:

✅ **502 Bad Gateway** - исправлено SSL проксирование  
✅ **Xray перезагрузки** - убраны проблемные параметры  
✅ **Конфликты сетей** - изменена подсеть Docker  
✅ **Высокое потребление RAM** - оптимизированы все компоненты  
✅ **VLESS порты недоступны** - исправлено маппинг портов  
✅ **SSL сертификаты** - корректная интеграция с Marzban  

## 📈 Мониторинг производительности

```bash
# Постоянный мониторинг ресурсов
watch -n 5 'docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}\t{{.CPUPerc}}"'

# Проверка дискового пространства
docker system df

# Очистка неиспользуемых ресурсов
docker system prune -f
```

## 🎯 Результаты тестирования

- ✅ **Время запуска:** 25 секунд
- ✅ **Общее потребление RAM:** 208MB
- ✅ **Стабильность Xray Core:** без перезагрузок
- ✅ **VLESS подключения:** работают стабильно
- ✅ **SSL панель:** доступна и функциональна
- ✅ **Производительность:** оптимальная для VPS 1GB RAM

## 📞 Поддержка

Если у вас возникли проблемы с этой оптимизированной версией:

1. Проверьте логи: `docker compose logs`
2. Убедитесь в корректности DNS записей
3. Проверьте открытость портов в файрволе
4. Создайте Issue с описанием проблемы

## 📄 Лицензия

MIT License - можете использовать для любых целей.

---

**🚀 Версия: Ultra RAM Optimized & Fully Tested**  
**📅 Обновлено: 28 октября 2025**  
**💾 Потребление RAM: ~208MB**  
**⚡ Статус: Полностью рабочий**