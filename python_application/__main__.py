# -*- coding: utf-8 -*-

import click
import logging
import sys
from .application import App

@click.command()
def hello_world():
    app = App()
    print(app.get_hello_world())

@click.group()
def main(args=None):
    """Command line utility"""
    logging.basicConfig(stream=sys.stderr, level=logging.INFO)

main.add_command(hello_world)

if __name__ == "__main__":
    sys.exit(main())
