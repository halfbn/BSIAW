from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required

def public_view(request):
    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Rejestracja zakończona sukcesem! Możesz się teraz zalogować.')
            return redirect('public')
    else:
        form = UserCreationForm()
    return render(request, 'public.html', {'form': form})

def login_view(request):
    next_url = request.GET.get('next') or request.POST.get('next')
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            messages.success(request, 'Zalogowano pomyślnie!')
            if next_url:
                return redirect(next_url)
            return redirect('private')
    else:
        form = AuthenticationForm()
    return render(request, 'login.html', {'form': form, 'next': next_url})

def logout_view(request):
    logout(request)
    messages.info(request, 'Wylogowano pomyślnie.')
    return redirect('public')

@login_required(login_url='login')
def private_view(request):
    return render(request, 'private.html')
