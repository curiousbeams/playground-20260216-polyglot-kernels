# slim uv base image
FROM python:3.14-slim-bookworm

# Copy uv
COPY --from=ghcr.io/astral-sh/uv /uv /uvx /bin/

# Copy Julia from official image
COPY --from=julia:1.10 /usr/local/julia /usr/local/julia
ENV PATH=/usr/local/julia/bin:$PATH

# uv optimization env variables
ENV UV_COMPILE_BYTECODE=1
ENV UV_SYSTEM_PYTHON=1

# install Python deps
COPY ./requirements.txt .
RUN uv pip install -r requirements.txt

# create user with a home directory for binder
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

WORKDIR ${HOME}
USER ${USER}

# Copy Julia package files and install packages
COPY --chown=${NB_UID}:${NB_UID} Project.toml ${HOME}/
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); Pkg.precompile()' \
    && julia -e 'using Pkg; Pkg.add("IJulia"); Pkg.build("IJulia")'

# Make sure the contents of our repo are in ${HOME}
COPY . ${HOME}
USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

# run jupyterlab
CMD ["jupyter", "lab"]
