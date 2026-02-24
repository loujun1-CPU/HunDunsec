#!/usr/bin/env python3
import subprocess
import os
import sys
os.environ['PYTHONIOENCODING'] = 'utf-8'
def run_command(cmd):
    print(f"\n===== 执行: {cmd} =====")
    try:
        result = subprocess.run(
            cmd, shell=True, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            encoding="utf-8"
        )
        print(f"成功: {result.stdout}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"失败: {e.stderr}")
        sys.exit(1)
def main():
    if os.geteuid() != 0:
        print("错误：请使用root用户运行")
        sys.exit(1)
    run_command('echo "deb https://launchpad.proxy.ustclug.org/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/php.list')
    run_command("apt-get update")
    run_command("apt-get install -y php7.4-fpm php7.4-mysql php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-gd php7.4-json php7.4-bcmath")
    run_command("apt-get install -y nginx")
    run_command("curl -sS https://getcomposer.org/installer | php")
    run_command("mv composer.phar /usr/local/bin/composer")
    run_command("systemctl restart nginx")
    run_command("systemctl start php7.4-fpm")
    run_command("mkdir -p /var/www/tp51_public && cd /var/www/tp51_public")
    run_command("rm -rf /var/www/tp51_public/vendor /var/www/tp51_public/composer.lock")
    run_command("sed -i 's/\"topthink\\/framework\": \"[^\"]*\"/\"topthink\\/framework\": \"5.1.41\"/g' /var/www/tp51_public/composer.json")
    run_command("cd /var/www/tp51_public && composer config repo.packagist composer https://mirrors.aliyun.com/composer/ && COMPOSER_ALLOW_SUPERUSER=1 composer install --ignore-platform-reqs --no-plugins --no-security-blocking")
    index_php_content = '''<?php
namespace think;
require __DIR__ . '/../thinkphp/base.php';
Container::get('app', [dirname(__DIR__)])->run()->send();
'''
    with open("/var/www/tp51_public/public/index.php", "w", encoding="utf-8") as f:
        f.write(index_php_content)
    run_command("rm -rf /var/www/tp51_public/runtime/*")
    run_command("chmod -R 777 /var/www/tp51_public/runtime")
    run_command("chown -R www-data:www-data /var/www/tp51_public")
    run_command("systemctl restart php7.4-fpm")
    nginx_config = '''server {
    listen 80;
    server_name _;
    root /var/www/tp51_public/public;
    index index.php index.html;
    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }
    location ~ \\.php$ {
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /runtime/ {
        deny all;
    }
}'''
    with open("/etc/nginx/sites-available/tp51.conf", "w", encoding="utf-8") as f:
        f.write(nginx_config)
    run_command("nginx -t && systemctl restart nginx")
    run_command("systemctl restart php7.4-fpm")
    run_command("cd /var/www/tp51_public && wget https://github.com/top-think/framework/archive/refs/tags/v5.1.42.zip -O framework.zip && unzip -o framework.zip && mkdir -p thinkphp && mv framework-5.1.42/* thinkphp/ && rm -rf framework-5.1.42 framework.zip && chown -R www-data:www-data thinkphp && chmod -R 755 thinkphp")
    run_command("systemctl restart php7.4-fpm && systemctl restart nginx")
    run_command("cd /var/www/tp51_public && sed -i 's/namespace app\\\\index\\\\controller;/namespace app\\index\\controller;/' application/index/controller/Index.php && echo \"<?php return ['default_module' => 'index'];\" > config/app.php && chown www-data:www-data application/index/controller/Index.php config/app.php")
    print("访问：http://服务器IP")
if __name__ == "__main__":
    main()
