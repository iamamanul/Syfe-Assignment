#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== WordPress Kubernetes Health Check ==="
echo ""

# Check 1: Kubernetes cluster
echo "1. Kubernetes Cluster:"
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "   ${GREEN}✓ Kubernetes cluster is accessible${NC}"
else
    echo -e "   ${RED}✗ Cannot connect to Kubernetes${NC}"
    exit 1
fi

# Check 2: WordPress pod
echo "2. WordPress Pod:"
WP_POD=$(kubectl get pods -l app=wordpress -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$WP_POD" ]; then
    WP_STATUS=$(kubectl get pod $WP_POD -o jsonpath='{.status.phase}')
    if [ "$WP_STATUS" = "Running" ]; then
        echo -e "   ${GREEN}✓ WordPress pod is running ($WP_POD)${NC}"
    else
        echo -e "   ${RED}✗ WordPress pod status: $WP_STATUS${NC}"
    fi
else
    echo -e "   ${RED}✗ WordPress pod not found${NC}"
fi

# Check 3: MySQL pod
echo "3. MySQL Pod:"
MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$MYSQL_POD" ]; then
    MYSQL_STATUS=$(kubectl get pod $MYSQL_POD -o jsonpath='{.status.phase}')
    if [ "$MYSQL_STATUS" = "Running" ]; then
        echo -e "   ${GREEN}✓ MySQL pod is running ($MYSQL_POD)${NC}"
    else
        echo -e "   ${RED}✗ MySQL pod status: $MYSQL_STATUS${NC}"
    fi
else
    echo -e "   ${RED}✗ MySQL pod not found${NC}"
fi

# Check 4: Services
echo "4. Services:"
kubectl get svc wordpress-service mysql-service 2>/dev/null && echo -e "   ${GREEN}✓ Services are running${NC}" || echo -e "   ${RED}✗ Services not found${NC}"

# Check 5: Port-forward
echo "5. Port-Forward:"
if ps aux | grep -q "[k]ubectl port-forward.*8080"; then
    echo -e "   ${GREEN}✓ Port-forward is running on 8080${NC}"
else
    echo -e "   ${YELLOW}⚠ Port-forward not running. Starting...${NC}"
    kubectl port-forward service/wordpress-service 8080:80 >/dev/null 2>&1 &
    sleep 2
    if ps aux | grep -q "[k]ubectl port-forward.*8080"; then
        echo -e "   ${GREEN}✓ Port-forward started${NC}"
    else
        echo -e "   ${RED}✗ Failed to start port-forward${NC}"
    fi
fi

# Check 6: WordPress access
echo "6. WordPress Web Access:"
sleep 2
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")
case $HTTP_STATUS in
    200|302|301)
        echo -e "   ${GREEN}✓ WordPress is accessible (HTTP $HTTP_STATUS)${NC}"
        echo "   Open: http://localhost:8080"
        ;;
    000)
        echo -e "   ${RED}✗ Cannot connect to WordPress${NC}"
        ;;
    *)
        echo -e "   ${YELLOW}⚠ WordPress returned HTTP $HTTP_STATUS${NC}"
        ;;
esac

# Check 7: Persistent Volumes
echo "7. Persistent Storage:"
PV_COUNT=$(kubectl get pv 2>/dev/null | grep -v NAME | wc -l)
PVC_COUNT=$(kubectl get pvc 2>/dev/null | grep -v NAME | wc -l)
if [ $PV_COUNT -gt 0 ] && [ $PVC_COUNT -gt 0 ]; then
    echo -e "   ${GREEN}✓ PV/PVC configured ($PV_COUNT PVs, $PVC_COUNT PVCs)${NC}"
else
    echo -e "   ${YELLOW}⚠ No PV/PVC found${NC}"
fi

echo ""
echo "=== Summary ==="
echo "To access WordPress:"
echo "1. Via port-forward: http://localhost:8080"
echo "2. Via NodePort: http://$(minikube ip 2>/dev/null || hostname -I | awk '{print $1}'):$(kubectl get svc wordpress-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)"
echo ""
echo "Troubleshooting commands:"
echo "  kubectl get pods"
echo "  kubectl logs <pod-name>"
echo "  kubectl describe pod <pod-name>"
