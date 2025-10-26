from django.shortcuts import render, redirect
from .forms import CommentForm
from .models import Comment
from django.contrib import messages
'''
zmienic tak zeby nie bylo autor komentarza tylko automatycznie zalogowany uzytkownik
'''
def comment_view(request):
    if request.method == 'POST':
        form = CommentForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Dodano komentarz')
    else:
        form = CommentForm()
    comments = Comment.objects.all().order_by('-created_at')
    return render(request, 'blog.html', {'form': form, 'comments': comments})