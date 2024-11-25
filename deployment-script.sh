cd /home/forge/growers.indexfresh.com

git pull origin $FORGE_SITE_BRANCH

$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader

echo 'Deleting temporary storage...'
rm -rf storage/app/scratch/*
rm -rf storage/app/sideloads/*
echo 'Done.'

echo 'Building app assets...'
npm install
npm run build
echo 'Done.'

echo 'Running pre-FPM restart artisan commands...'
if [ -f artisan ]
then
    $FORGE_PHP artisan migrate --force
    $FORGE_PHP artisan config:cache
    $FORGE_PHP artisan event:cache
    $FORGE_PHP artisan route:cache
    $FORGE_PHP artisan storage:link
    $FORGE_PHP artisan view:cache
fi
echo 'Done.'

( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $FORGE_PHP_FPM reload ) 9>/tmp/fpmlock
