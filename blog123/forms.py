from django import forms
from .models import Comment

class CommentForm(forms.ModelForm):
    class Meta:
        model = Comment
        fields = ['author', 'content']
    def clean_content(self):
        comment = self.cleaned_data["content"]
        if len(comment)>400:
            raise forms.ValidationError("komentarz nie moze byc dluzszy nic 400 znakow")
        return comment
    
