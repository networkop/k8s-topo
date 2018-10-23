from setuptools import setup
import os

EXTRA_FILES='examples'

def collect_files():
    return [(d, [os.path.join(d,f) for f in files])
            for d, folders, files in os.walk(EXTRA_FILES)]

requirements = list()
with open('requirements.txt') as f:
    requirements = f.read().splitlines()

setup(
    name='k8s-topo',
    version='2.0',
    scripts=['bin/k8s-topo'],
    data_files=collect_files(),
    python_requires='>=3.6',
    install_requires=requirements,
    url='https://github.com/networkop/k8s-topo',
    license='BSD3',
    author='Michael Kashin',
    author_email='mkashin@arista.com',
    description='K8s network topology builder'
