import os
from django.http import HttpResponse
import multiprocessing 
import math
doodoo = os.environ['wai']


def f(x):
    new_int=0
    for doodoo in range (x):
        new_int=math.factorial(x+1)-math.factorial(x)
    return new_int

def index(request):
    return HttpResponse("Sixth code being deployed" + doodoo + 
                        '<img src="https://www.dailydot.com/wp-content/uploads/534/ff/76995fe1e177a932-2048x1024.jpg">'
                       )

def test(request,multipler=2):
    jobs = []
    if(multipler>50):
        return HttpResponse("multipler too big")
    for i in range (multipler):
        p=multiprocessing.Process(target=f,args=(1500,))
        jobs.append(p)
        p.start()
    return HttpResponse("HELLO PEOPLE FROM THE WORLD~~~ "+doodoo)

