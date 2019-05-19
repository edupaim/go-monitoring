package main

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/client_golang/prometheus/push"
	"net/http"
)

const pushgatewayAddr = "http://pushgateway:9091"
const applicationPort = ":2112"

func main() {
	println("starting server...")
	version := prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "version",
		Help: "Version information about this service",
		ConstLabels: map[string]string{
			"version": Version,
			"service": ApplicationName,
		},
	})
	prometheus.MustRegister(version)
	// Easy case:
	counter := prometheus.NewCounter(prometheus.CounterOpts{
		Name: "counter_app",
		Help: "Counter test",
	})
	prometheus.MustRegister(counter)
	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		counter.Inc()
		err := push.New(pushgatewayAddr, ApplicationName).
			Collector(counter).
			Push()
		if err != nil {
			panic(err)
		}
		err = push.New(pushgatewayAddr, ApplicationName).
			Collector(version).
			Push()
		if err != nil {
			panic(err)
		}
		handler := promhttp.Handler()
		handler.ServeHTTP(w, r)
	})
	if err := http.ListenAndServe(applicationPort, nil); err != nil {
		panic(err)
	}
}
