#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2021 DevPanel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation version 3 of the
# License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# For GNU Affero General Public License see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------

#== If webRoot has not been difined, we will set appRoot to webRoot
if [[ ! -n "$WEB_ROOT" ]]; then
  export WEB_ROOT=$APP_ROOT
fi

STATIC_FILES_PATH="$WEB_ROOT/files/"
SETTINGS_FILES_PATH="$WEB_ROOT/settings.php"
DEFAULT_SETTINGS_FILE="https://raw.githubusercontent.com/backdrop/backdrop/1.19.1/settings.php"

#== Install drush locally
rm $APP_ROOT/drush -fR
curl -sLo /tmp/drush.zip https://github.com/drush-ops/drush/archive/8.x.zip
unzip -qo /tmp/drush.zip -d /tmp/drush && mv /tmp/drush/drush-8.x $APP_ROOT/drush && rm /tmp/drush.zip
cd $APP_ROOT/drush && composer install

#== Add Backdrop Drush extension
mkdir -p  $APP_ROOT/drush/commands && cd $APP_ROOT/drush/commands
rm backdrop -fR
curl -sLo backdrop-drush.zip https://github.com/backdrop-contrib/backdrop-drush-extension/archive/1.x-1.x.zip
unzip -qo backdrop-drush.zip -d backdrop && rm backdrop-drush.zip
drush cc drush

#== Extract static files
if [[ -f "$APP_ROOT/.devpanel/dumps/files.tgz" ]]; then
  mkdir -p $STATIC_FILES_PATH
  tar xzf "$APP_ROOT/.devpanel/dumps/files.tgz" -C $STATIC_FILES_PATH
fi

#== Import mysql files
if [[ -f "$APP_ROOT/.devpanel/dumps/db.sql.tgz" ]]; then
  SQLFILE=$(tar tzf $APP_ROOT/.devpanel/dumps/db.sql.tgz)
  tar xzf "$APP_ROOT/.devpanel/dumps/db.sql.tgz" -C /tmp/
  mysql -h$DB_HOST -u$DB_USER -p$DB_PASSWORD $DB_NAME < /tmp/$SQLFILE
  rm /tmp/$SQLFILE
fi

#== Create settings files
if [[ -f "$SETTINGS_FILES_PATH" ]]; then
  sudo mv $SETTINGS_FILES_PATH $SETTINGS_FILES_PATH.old
fi
curl -o $SETTINGS_FILES_PATH $DEFAULT_SETTINGS_FILE --silent
sed -i -e "s/^\$database =.*/\$database = 'mysql:\/\/$DB_USER:$DB_PASSWORD@$DB_HOST\/$DB_NAME';/g" $SETTINGS_FILES_PATH

#== Rename config directory
sudo mv $STATIC_FILES_PATH/$(ls $STATIC_FILES_PATH -a | grep "config_") $STATIC_FILES_PATH/$(echo 'echo "config_" . md5($database);' | cat $SETTINGS_FILES_PATH - | php)

#== Update permission
sudo find $APP_ROOT -type f -exec chmod 664 {} \;
sudo find $APP_ROOT -type d -exec chmod 775 {} \;
sudo chown -R www:www-data $APP_ROOT