# generic-python-docker/tests/test_application.py
import pytest

from python_application/application.py import App

@pytest.fixture
def app():
    return App()

class TestApplication(object):

def test_return_value(self, app):
    assert app.get_hello_world() == "Hello, World"
