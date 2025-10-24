from django.db import models



#tworzenie modelu bazy danych komentarzy
class Comment(models.Model):
    content = models.TextField()
    author = models.CharField(max_length=200)
    #mozna dodac ze komentarze nie moga byc czesciej niz x czasu!!!
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return f"Komentarz {self.author}"


