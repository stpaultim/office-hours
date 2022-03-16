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

#== Init Backdrop
cd /tmp && curl -sLo backdrop.tar.gz https://github.com/backdrop/backdrop/tarball/1.19.1
tar xzf backdrop.tar.gz -C $APP_ROOT --strip-components=1

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

#== Site Install Drush
cd $APP_ROOT
drush si --account-name=devpanel --account-pass=devpanel --db-url=mysql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME -y
drush cc all

#== Update permission
sudo find $APP_ROOT -type f -exec chmod 664 {} \;
sudo find $APP_ROOT -type d -exec chmod 775 {} \;
sudo chown -R www:www-data $APP_ROOT
