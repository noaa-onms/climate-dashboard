# setup
# https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container
#   sudo su -
#   apt-get update && apt-get -y install cron
#   ln -s /share/github/noaa-onms/climate-dashboard/scripts/update_dashboard.crontab /etc/cron.d/update_dashboard.crontab
#   chmod 0644 /etc/cron.d/update_dashboard.crontab
#   rm /etc/cron.d/update_dashboard.crontab
#   DIR_REPO=/share/github/noaa-onms/climate-dashboard
#   CRON_REPO=$DIR_REPO/scripts/update_dashboard.crontab
#   CRON_SYS=/etc/cron.d/update_dashboard
#   CRON_LOG=/var/log/cron.log
#   ln -s $CRON_REPO $CRON_SYS
#   chmod 0644 $CRON_SYS
#   touch $CRON_LOG
# store git credentials
# https://stackoverflow.com/questions/56057292/git-push-using-crontab-every-hour-prompting-password
#   cd $DIR_REPO
#   git config credential.helper store
$ git push http://example.com/repo.git
Username: <type your username>
Password: <type your password>

# git config credential.helper store
# check
#   crontab -l
#   service cron status
#   cat /var/log/cron.log
#   grep CRON /var/log/syslog
#   grep CRON /var/log/syslog


# cron && tail -f /var/log/cron.log
# ls -la /etc/cron.d/
#
# chmod 0744 /share/github/noaa-onms/climate-dashboard/scripts/update_dashboard.sh

WD=/share/github/noaa-onms/climate-dashboard
cd $WD
Rscript scripts/get_data.R
Rscript scripts/make_pages.R
git config --global --add safe.directory $WD
git config --local user.name "bbest"
git config --local user.email "ben@ecoquants.com"
git add --all
git commit -m 'Update Dashboard ben@ecoquants.com' || echo "No changes to commit"
git push origin || echo "No changes to commit"

