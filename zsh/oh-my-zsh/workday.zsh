alias prod='kubectx produs; sso-cli aws --application Firefox' # to authenticate to prod and switch the kubectl context to point to it
alias eng='kubectx eng1; okta2aws login' # to authenticate to eng and switch the kubectl context to point to it
alias grafana='open http://localhost:3000; kubectl -n monitoring port-forward svc/watchdog-grafana 3000:80' # port forward watchdog grafana and open browser page pointing to it
alias grafanap='kubectl -n monitoring port-forward svc/watchdog-grafana 3000:80' # for when the port forward breaks
alias prometheus='open "http://localhost:8001/api/v1/namespaces/monitoring/services/watchdog-prometheus:http-web/proxy/alerts"; kubectl proxy' # same for prometheus, firing alerts page
# copy the argocd admin password, then open the argoapp page. You can then paste the password into the admin password form field
alias argo='kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | pbcopy; open http://localhost:8080; kubectl -n argocd port-forward svc/argocd-server 8080:443' 
alias argop='kubectl -n argocd port-forward svc/argocd-server 8080:443' # for when the port-forward breaks
alias pods='kubectl get pod -w' # watch for pods in current namespace

WORKDAY=~/Code/workday