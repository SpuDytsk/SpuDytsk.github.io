# Elecard Boro documents template

This theme is used to design all web documents produced by Elecard Boro. Currently Elecard theme based on Alabaster Sphinx theme.

This template contents only some common files and custom css used in theme. Other parts are building from the Sphinx installed resources. Also you should know that main settings relaited to the theme usage are in `conf.py` file of your web-doc project.

## Alabaster

> Alabaster is a visually (c)lean, responsive, configurable theme for the Sphinx documentation system. It is Python 2+3 compatible.
> 
> It began as a third-party theme, and is still maintained separately, but as of Sphinx 1.3, Alabaster is an install-time dependency of Sphinx and is selected as the default theme.

*   [Alabaster theme]( https://alabaster.readthedocs.io/en/latest/)
*   [Alabaster theme customization](https://alabaster.readthedocs.io/en/latest/customization.html)

## How to add this template to the web-doc project

You need add submodule to your broject (execute from project root) :
```
git submodule add -f git@gitlab.elecard.net.ru:boro/docs/doc-template.git ./_static_template
```
The `static_template` folder with submodule content will be created (Do not make this folder by yourself!). 

`.gitmodules`hidden file created automaticaly as well. Do not add this file to `.gitignore`!

## Sphinx build requirements

* **Sphinx v2.2.0** and newer
* **Python 3**

Check Sphinx version:
```
sphinx-build --version
```

Installation Python 3 (and latest Spinx):
```
sudo apt install python3-pip
pip3 install sphinx
```

You may have to set path to the sphinx-build compiler if the make process cant find it:
```
export PATH=$PATH:~/.local/bin
```
Use this way to add permanent path to sphinx-build (restart terminal after set):
```
cat >>~/.bashrc <<'EOF'
PATH=$PATH:~/.local/bin
EOF
```
