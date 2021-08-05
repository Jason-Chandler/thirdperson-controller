(in-package :thirdperson-controller)

(defparameter *mouse-speed* 5.4)

(defparameter *movement-speed* 0.1)

(defun set-up-camera (camera)
  (let ((eulers (vec3))
        (app (ffi:ref js:pc app))
        (ray-end (find-by-name "RAYCAST-ENDPOINT")))
    (labels ((on-mouse-move (e &rest _)
               (if (eql ((ffi:ref js:pc -mouse is-pointer-locked)) js:true)
                   (progn 
                     (js-setf (eulers x) (- (ffi:ref eulers x)
                                                    (mod (* (* *mouse-speed* (ffi:ref e dx)) 0.01666666) 360))
                              (eulers y) (+ (ffi:ref eulers y) (mod (* (* *mouse-speed* (ffi:ref e dy)) 0.01666666) 360)))
                     (if (< (ffi:ref eulers x) 0)
                         (ffi:set (ffi:ref eulers x) (+ (ffi:ref eulers x) 360)))
                     (if (< (ffi:ref eulers y) 0)
                         (ffi:set (ffi:ref eulers y) (+ (ffi:ref eulers y) 360))))))
             (on-mouse-down (e &rest _)
               ((ffi:ref app mouse enable-pointer-lock)))
             (get-world-point (&rest _)
               (let* ((from ((ffi:ref camera parent get-position)))
                      (to ((ffi:ref ray-end get-position)))
                      (hit ((ffi:ref app systems rigidbody raycast-first) from to)))
                 (if (not (eql hit js:null))
                     (ffi:ref hit point)
                     to)))
             (p-update (dt &rest _)
               (let* ((origin-entity (ffi:ref camera parent))
                     (target-y (+ (ffi:ref eulers x) 180))
                     (target-x (ffi:ref eulers y))
                     (target-ang (vec3 :x (- target-x) :y target-y)))
                 ((ffi:ref origin-entity set-euler-angles) target-ang)
                 ((ffi:ref camera set-position) (funcall #'get-world-point))
                 ((ffi:ref camera look-at) origin-entity)))
             (update-movement (dt &rest _)
               (let* ((entity (ffi:ref camera parent parent))
                     (world-direction (vec3))
                     (temp-direction (vec3))
                     (forward (ffi:ref entity forward))
                     (right (ffi:ref entity right))
                     (x 0)
                     (z 0))
                 (if (is-pressed-p "KEY_A")
                     (decf x))
                 (if (is-pressed-p "KEY_D")
                     (incf x))
                 (if (is-pressed-p "KEY_W")
                     (incf z))
                 (if (is-pressed-p "KEY_S")
                     (decf z))

                 (if (or 
                      (not (zerop x))
                      (not (zerop z)))
                     (progn
                       ((ffi:ref world-direction add) 
                        ((ffi:ref ((ffi:ref temp-direction copy) forward) mul-scalar) z))
                       ((ffi:ref world-direction add) 
                        ((ffi:ref ((ffi:ref temp-direction copy) right) mul-scalar) x))
                       ((ffi:ref world-direction normalize))
                       (let* ((pos (vec3 :x (* (ffi:ref world-direction x) dt)
                                        :z (* (ffi:ref world-direction z) dt)))
                             (target-y (+ (ffi:ref eulers x) 180))
                             (rot (vec3 :y target-y)))
                         ((ffi:ref ((ffi:ref pos normalize)) scale) *movement-speed*)
                         ((ffi:ref pos add) ((ffi:ref entity get-position)))
                         (teleport entity
                                   :x (ffi:ref pos x)
                                   :y (ffi:ref pos y)
                                   :z (ffi:ref pos z)
                                   :rot-x (ffi:ref rot x)
                                   :rot-y (ffi:ref rot y)
                                   :rot-z (ffi:ref rot z)
                                   :keep-vel t)))))))
      (on mousemove (ffi:ref app mouse) #'on-mouse-move camera)
      (on mousedown (ffi:ref app mouse) #'on-mouse-down camera)
      (add-to-update :cam #'p-update)
      (add-to-update :movement #'update-movement))))



