# tests/test_app.py

import Pytest
from python_application.application import App

@pytest.fixture
def app():
    return App()

class TestApplication:
    def test_return_value(self, app):
        assert app.get_hello_world() == "Hello, World"
