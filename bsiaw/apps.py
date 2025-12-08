from django.apps import AppConfig

class Blogconf(AppConfig):
    name = "bsiaw"

    def ready(self):
        import bsiaw.signals
