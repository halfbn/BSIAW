from django.shortcuts import render, redirect
from .forms import CommentForm
from .models import Comment, Profil
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from datetime import timedelta

'''
zmienic tak zeby nie bylo autor komentarza tylko automatycznie zalogowany uzytkownik
'''
@login_required
def comment_view(request):
    comments = Comment.objects.all().order_by('-created_at')

    username = request.user.username
    profil, _ = Profil.objects.get_or_create(user=request.user)
    czekac = timedelta(minutes=1)
    if request.method == 'POST':
        form = CommentForm(request.POST)
        now = timezone.now()
        print(profil.last_commented)
        if profil.last_commented and (now - profil.last_commented) < czekac:
            zostalo = int((czekac - (now - profil.last_commented)).total_seconds())
            messages.error(request, "Możesz dodawać komentarze tylko raz na minutę. Spróbuj ponownie za " + str(zostalo) + " sekund.")
            return render(request, 'blog.html', {'form': form, 'comments': comments, 'username': username})
        if form.is_valid():
            comment = form.save(commit=False)
            comment.author = username #nazwa użytkownika jest ściągania z żądania
            form.save()

            profil.last_commented = now
            profil.save()

            messages.success(request, 'Dodano komentarz.')
    else:
        form = CommentForm()

    return render(request, 'blog.html', {'form': form, 'comments': comments, 'username': username})