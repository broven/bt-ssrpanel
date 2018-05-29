#!/bin/bash
#宝塔ssrpanel快速部署工具
rm -rf $0
echo -e "感谢使用 “\033[35m 宝塔ssrpanel快速部署工具 \033[0m”"
echo "----------------------------------------------------------------------------"
echo "请注意这个要求：php版本=7.1，添加网址时候注意版本选择必须为PHP7.1,添加完成后地址不要改动！"
echo "----------------------------------------------------------------------------"
echo "请输入宝塔面板添加的网站域名：(请不要修改添加之后的默认地址，只输入域名即可)"
read web
echo "请输入宝塔面板添加的MySQL用户名："
read mysqlu
echo "请输入宝塔面板添加的MySQL密码："
read mysqlp
sleep 1
echo "请等待系统自动操作......"
yum update -y
yum install epel-* -y
yum install gcc  gcc-c++ unzip zip   -y 
vphp='7.1'
version='71'
echo "正在安装fileinfo到服务器......";
extFile='/www/server/php/70/lib/php/extensions/no-debug-non-zts-20160303/fileinfo.so'
if [ ! -d "/www/server/php/71/src/ext/fileinfo" ];then
wget -O ext-71.zip https://coding.net/u/cvc/p/ssrpanel/git/raw/master/ext-71.zip
unzip -o ext-71.zip -d /www/server/php/71/ > /dev/null
rm -f ext-71.zip
fi
cd /www/server/php/71/
mv ext-71 ext
cd /www/server/php/71/ext/fileinfo
/www/server/php/71/bin/phpize
./configure --with-php-config=/www/server/php/71/bin/php-config
make && make install
echo -e " extension = \"fileinfo.so\"\n" >> /www/server/php/71/etc/php.ini
service php-fpm-71 reload
echo '==============================================='
echo 'fileinfo安装完成!'
sleep 1
echo "正在安装依赖环境......";
sleep 2
cd /www/wwwroot/$web
rm -rf index.html 404.html
#安装git,unzip工具
yum install git unzip -y 
wget --no-check https://github.com/4kercc/bt-ssrpanel/raw/master/V3.4.zip
unzip V3.4.zip
mv SSRPanel-3.4 ssrpanel
cd ssrpanel/
sed -i 's/proc_open,//g' /www/server/php/71/etc/php.ini
sed -i 's/proc_get_status,//g' /www/server/php/71/etc/php.ini     
sed -i "s/'database' => 'ssrpanel'/'database' => '$mysqlu'/g" /www/wwwroot/$web/ssrpanel/config/database.php
sed -i "s/'username' => 'root'/'username' => '$mysqlu'/g" /www/wwwroot/$web/ssrpanel/config/database.php
sed -i "s/'password' => 'root'/'password' => '$mysqlp'/g" /www/wwwroot/$web/ssrpanel/config/database.php
cd /www/wwwroot/$web/ssrpanel/sql
mysql -u$mysqlu -p$mysqlp $mysqlu < db.sql >/dev/null 2>&1
cd ..
php composer.phar install
clear
echo "------------------------------"
echo "即将出现的界面请输入yes继续"
echo "------------------------------"
php artisan key:generate
chown -R www:www storage/
chmod -R 777 storage/
sleep 3
#修改伪静态以及默认路径
sed -i "s/www\/wwwroot\/$web/www\/wwwroot\/$web\/ssrpanel\/public/g" /www/server/panel/vhost/nginx/$web.conf
echo '
location / {
try_files $uri $uri/ /index.php$is_args$args;
}
' >/www/server/panel/vhost/rewrite/$web.conf
echo "正在重启php&Nginx服务..."
service php-fpm-71 reload
service nginx reload
echo "----------------------------------------------------------------------------"
echo "部署完成，请打开http://$web即可浏览"
echo "如果打不开站点，请到宝塔面板中软件管理重启nginx和php7.1"
echo "这个原因触发几率<10%，原因是修改配置后需要重启Nginx服务和php服务才能正常运行"
echo "----------------------------------------------------------------------------"
