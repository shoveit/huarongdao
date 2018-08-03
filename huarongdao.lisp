;(load "/home/asenal/Documents/huawei/E70/ag-restful/agraph-6.4.1-linuxamd64.64-direct-client-lisp-acl10.1/agraph.fasl")
(in-package :db.agraph.user)
(register-namespace "diaodu" "http://tianchi.com/machinedispatch#")
(enable-!-reader)  
(enable-print-decoded t)

;;-- An interference rule define Max amount of app2 is allowed to deploy if app1 is deployed to the same machine.
(<-- (interference ?app1 ?app2 ?X)
	 (q- ?r !diaodu:A ?app1)
	 (q- ?r !diaodu:B ?app2)
	 (q- ?r !diaodu:X ?X))

(<-- (machine-app ?machine ?app)
	 (q- ?instance !diaodu:runningOn ?machine)
	 (q- ?app !diaodu:deployTo ?instance))

(<-- (machine-app-cnt ?machine ?app ?cnt)
	 (machine-app ?machine ?app)
	 (bagof ?app (machine-app ?machine ?app) ?apps)
	 (length ?apps ?cnt))

(<-- (conflict ?machine ?app1 ?app2 ?cnt ?X)
	 (machine-app ?machine ?app1)
	 (machine-app-cnt ?machine ?app2 ?cnt)
	 (interference ?app1 ?app2 ?X)
	 (lispp (>= ?cnt (upi->number ?X))))


(select  (?machine ?app1 ?app2 ?X ?cnt)
  (conflict ?machine ?app1 ?app2 ?cnt ?X))
---------timeout


;;; rule test----------------	 
; ("http://tianchi.com/machinedispatch#machine_4448"
;  "http://tianchi.com/machinedispatch#app_3327"
;  "http://tianchi.com/machinedispatch#app_3327" 1 0)

;;---test: (time (select (?machine ?app ?cnt) (machine-app-cnt ?machine ?app ?cnt)))
;; cpu time (non-gc) 25.717512 sec user, 0.479990 sec system
;;---test: (time (select (?app ?cnt) (machine-app-cnt !diaodu:machine_1154 ?app ?cnt)))
;; cpu time (non-gc) 0.048482 sec user, 0.000008 sec system

;;(select (?X ?A ?B)
;;  (:limit 32)
;;  (q- ?X !diaodu:A ?A) (q- ?X !diaodu:B ?B) (q- ?X !diaodu:X !"3"^^xsd:integer ))
;;
;;(select (?X ?A ?C)
;;  (q- ?X !diaodu:A ?A) (q- ?X !diaodu:B !diaodu:app_1919) (q- ?X !diaodu:X ?C))

;;;------------- HTTP interface
;;(db.agraph.user::custom-service
;;	;; 	"curl  -u super:123 localhost:10035/repositories/diaodu_sample/custom/machine-app-cnt -X GET --data 'machine=machine_805&app=832'"
;;	:get "r" "machine-app-cnt"
;;	:dynamic ((machine :string)
;;			  (app :string))
;;  (car (select (?machine ?app ?cnt)
;;	(lisp ?machine (resource machine "diaodu"))
;;	(lisp ?app (resource app "diaodu"))
;;	(machine-app-cnt ?machine ?app ?cnt))))
	 
