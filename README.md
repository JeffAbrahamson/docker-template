# Docker Template

Docker scripts and config for starting new projects, making it
relatively easy to run shells, build and test software, start claude
code.

This assumes a convenience bash function something like this so that
`dm sh`, `dm buld`, `dm test`, `dm claude` and so forth make sense.

    dm ()
    {
        if [ -r docker/docker-manage.sh -a -x docker/docker-manage.sh ]; then
            ( cd docker && ./docker-manage.sh $* );
        else
            echo "No docker-manage.sh present.";
        fi
    }

Copy the `docker/` directory to new projects, then modify as needed.
