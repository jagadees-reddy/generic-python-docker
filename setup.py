#!/usr/bin/env python

from setuptools import setup, find_packages

try:
    with open('README.md', 'r') as f:
        readme = f.read()
except FileNotFoundError:
    readme = ''

setup(
    name='python_application',
    description='A sample application',
    author='Frank Bertsch',
    author_email='frank@mozilla.com',
    url='https://github.com/jagadees-reddy/generic-python-docker',
    packages=find_packages(exclude=['tests', 'tests.*']),
    entry_points={
        'console_scripts': [
            'python_application=python_application.__main__:main',
        ],
    },
    python_requires='>=3.6.0',
    version='0.0.1',
    long_description=readme,
    include_package_data=False,
    install_requires=[
        'click',
    ],
    license='Mozilla',
)

