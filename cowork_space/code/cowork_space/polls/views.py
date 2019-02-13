import os
from django.http import HttpResponse
import multiprocessing 
import math
ENVAR = os.environ['wai']


def f(x):
    new_int=0
    for temp in range (x):
        new_int=math.factorial(x+1)-math.factorial(x)
    return new_int

def index(request):
    return HttpResponse('
<!DOCTYPE html>
<html>
<h1>Sample E-commerce website</h1>
<h2>No more 404 demo page</h2>
<h3>instance id='+ENVAR+'</h3>
<div>
<img src="https://www.accountingweb.com/sites/default/files/styles/banner/public/security_breach_weerapatkiatdumrong.jpg?itok=nczbk1pC" style="max-width:100%;">
</div>
</html>'
 )
        


def test(request,multipler=2):
    jobs = []
    if(multipler>50):
        return HttpResponse("multipler too big")
    for i in range (multipler):
        p=multiprocessing.Process(target=f,args=(1500,))
        jobs.append(p)
        p.start()
    return HttpResponse("This is home page "+ENVAR)

