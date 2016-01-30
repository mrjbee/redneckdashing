# Redneck dashboard
_Redneck_ dashboard is just a dashing dashboard with customized style and customs components. Check out http://shopify.github.com/dashing for more information about _Dashing_ project itself.

## Motivation
Main motivation is a quick setup of dashboard with a widgets which I use in my main projects as well as for developing new widgets

## Custom Widgets
Widget design is a litle bit different from which is supposed to be used by guys from Dashing. Main cause is project sensative information which is restricted to be shared to github (e.g. user/password, private links ans so on). Because of that `dashing install GIST_ID` in most cases will not work, as so Ive not botering my self with providing gists, as result if you would like to use any of widget you will have to copy them manually. I would suggest to check this folder and files out:
 
 * ./jobs - for event construct and schedule logic as well as dependencies from _./lib/.._ folder  
 * ./lib/.. - most of widget logics are incapsulated in separate modules    
 * ./lib/setup.rb.example - example of widget configuration
 * ./dashboards/.. - for dashboard configurations
 * ./dashboard/redneck.erb.example - example of job widgets setup

### CI Widget & Jenkins Job
Display status and progress of last jenkins job build
_TODO_ more details

### CI Cartoon Widget & Jenkins Set Job
Display status based on multiple jenkins jobs last builds
_TODO_ more details

### OMR(open merge request) & Gitlab Project Explore Job 
Display carrusel of gitlab open request for several projects
_TODO_ more details

## Screencast
![Alt text](/demoscreen.png?raw=true "Redneck Example Dashboard")
