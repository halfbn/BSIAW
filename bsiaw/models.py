from django.db import models
from django.utils import timezone

class RegistrationAttempt(models.Model):
    ip_address = models.GenericIPAddressField()
    timestamp = models.DateTimeField(default=timezone.now)

    class Meta:
        indexes = [
            models.Index(fields=['ip_address']),
            models.Index(fields=['timestamp'])
            ]
