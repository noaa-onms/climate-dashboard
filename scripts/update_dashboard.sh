WD=/share/github/noaa-onms/climate-dashboard
cd $WD
Rscript scripts/get_data.R
Rscript scripts/make_pages.R
git config --global --add safe.directory $WD
git config --local user.name "bbest"
git config --local user.email "ben@ecoquants.com"
git add --all
git commit -m 'Update Dashboard github-actions[bot]@users.noreply.github.com' || echo "No changes to commit"
git push origin || echo "No changes to commit"

