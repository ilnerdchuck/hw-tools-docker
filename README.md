# hw-tools-docker

Docker with tools to develop Hardware related projects available on ![Docker Hub](https://hub.docker.com/r/ilnerdchuck/hw_tools)

| Left-aligned   | slim               |          full      |
| :---           |     :---:          |          ---:      |
| Modelsim 22.04 | :white_check_mark: | :white_check_mark: |
| noVNC          |                    | :white_check_mark: |

## Docker Image Info

```
username: dockeruser
password: password
```

## Starting the docker

The docker can be started with this command that exposes SSH and the noVNC gui

```

docker run -d -p 2222:22 -p 5901:5901 -p 6080:6080 --name hw_tools ilnerdchuck/hw_tools:full

```

Otherwise a docker compose can be used and an example is given in the `docker-compose.yml` file, you can copy it and start it or customize it so suits your needs.

## SSH

SSH is enabled and available with X11 forwarding at port `2222`

## noVNC

In the full version the machine has a gui available at the address 
```
http://localhost:6080/vnc.html)
```
