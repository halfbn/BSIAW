from django.shortcuts import render, redirect
from .forms import CommentForm
from .models import Comment
from django.contrib import messages
from django.contrib.auth.decorators import login_required
import os

'''
zmienic tak zeby nie bylo autor komentarza tylko automatycznie zalogowany uzytkownik
'''
@login_required
def comment_view(request):
    # Wczytaj artykuł z pliku
    article_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'article.txt')
    with open(article_path, encoding='utf-8') as f:
        article_text = f.read()
    if request.method == 'POST':
        form = CommentForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Dodano komentarz')
    else:
        form = CommentForm()
    comments = Comment.objects.all().order_by('-created_at')
    return render(request, 'blog.html', {'form': form, 'comments': comments, 'article_text': article_text})