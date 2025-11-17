from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver


#tworzenie modelu bazy danych komentarzy
class Comment(models.Model):
    content = models.TextField()
    author = models.CharField(max_length=200)
    #mozna dodac ze komentarze nie moga byc czesciej niz x czasu!!!
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return f"Komentarz {self.author}"


class Profil(models.Model): #model, który 1:1 ściąga użytkowników ale do tego możemy dodawać własne pola
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    last_commented = models.DateTimeField(null=True, blank=True)
    def __str__(self):
        return self.user.username

@receiver(post_save, sender=User)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    if created:
        Profil.objects.create(user=instance)
    else:
        instance.profil.save()