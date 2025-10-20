from django.shortcuts import render

def public_view(request):
    return render(request, 'public.html')

def private_view(request):
    return render(request, 'private.html')
