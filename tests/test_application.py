# generic-python-docker/tests/test_application.py
import pytest

from generic_python_docker import application  # Ensure this import is correct


@pytest.fixture
def app():
    return application()


class TestApplication(object):

def test_return_value(self, application):
    assert application.get_hello_world() == "Hello, World"
