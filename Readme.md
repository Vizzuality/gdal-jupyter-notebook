# Jupyter notebooks with GDAL

This Dockerfile raises a Jupyter notebook on your local machine, with
GDAL preinstalled and some conda packages preinstalled. Just run
`jupyter.sh develop` and you'll be able to start hacking on a
batteries-included data science notebook.

This project is heavily based on the marvellous work
of [the Jupyter team](https://github.com/jupyter/docker-stacks), who
deserve all the praise. This is a slimmed down version of their stack,
with many packages not installed -such as a complete LaTeX
distribution, and some extras, such as GDAL (with python libs) and
Rasterio.

Whatever you place in the `work` directory will be available in the
Jupyter environment's root.
