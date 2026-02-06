dm ()
{
    if [ -r docker/docker-manage.sh -a -x docker/docker-manage.sh ]; then
        ( cd docker && ./docker-manage.sh "$@" );
    else
        echo "No docker-manage.sh present.";
    fi
}
