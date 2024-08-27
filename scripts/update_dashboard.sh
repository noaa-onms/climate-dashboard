# set git credentials on server
# https://stackoverflow.com/questions/56057292/git-push-using-crontab-every-hour-prompting-password
#   DIR_REPO=/share/github/noaa-onms/climate-dashboard
#   cd $DIR_REPO
#   git config credential.helper store
# setup crontab on server
# https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container
#   sudo su -
#   apt-get update && apt-get -y install cron
#   DIR_REPO=/share/github/noaa-onms/climate-dashboard
#   CRON_REPO=$DIR_REPO/scripts/update_dashboard.crontab
#   CRON_SYS=/etc/cron.d/update_dashboard
#   CRON_LOG=/var/log/cron.log
#   ln -s $CRON_REPO $CRON_SYS
#   chmod 0744 $CRON_SYS
#   touch $CRON_LOG
# check crontab on server
#   crontab -l
#   service cron status
# run this script once
#   /share/github/noaa-onms/climate-dashboard/scripts/update_dashboard.sh >> /var/log/cron.log 2>&1
#   cat /var/log/cron.log
WD=/share/github/noaa-onms/climate-dashboard
cd $WD
git pull
Rscript scripts/get_data.R
Rscript scripts/make_pages.R
git config --global --add safe.directory $WD
git config --local user.name "bbest"
git config --local user.email "ben@ecoquants.com"
git add --all
git commit -m 'Update Dashboard on rstudio.marinebon.app' || echo "No changes to commit"
git push origin || echo "No changes to commit"

