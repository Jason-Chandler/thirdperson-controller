(in-package :thirdperson-controller)

(defparameter *rotation-helper* (ffi:new (ffi:ref "pc.Entity") #j"MODEL-AXIS"))
(defparameter player-model (ffi:new (ffi:ref "pc.Entity") #j"PLAYER-MODEL"))
(defparameter *rotation-factor* 5)

(defun set-up-model (player asset-path)
  (let ((camera (find-by-name "CAMERA")))
    ((ffi:ref player add-child) player-model)
    ((ffi:ref player add-child) *rotation-helper*)
    (load-glb player-model asset-path js:true)
    (labels ((update-movement (dt &rest _)
               (let* ((forward (ffi:ref camera forward))
                     (right (ffi:ref camera right))
                     (x 0)
                     (z 0)
                     (inverted-target (vec3 :x (ffi:ref ((ffi:ref camera get-position)) x)
                                            :y (ffi:ref ((ffi:ref player get-position)) y)
                                            :z (ffi:ref ((ffi:ref camera get-position)) z)))
                     (rot (ffi:new (ffi:ref "pc.Quat"))))
                 (if (is-pressed-p "KEY_A")
                     (decf x))
                 (if (is-pressed-p "KEY_D")
                     (incf x))
                 (if (is-pressed-p "KEY_W")
                     (incf z))
                 (if (is-pressed-p "KEY_S")
                     (decf z))
                 ((ffi:ref *rotation-helper* look-at) inverted-target)
                 ((ffi:ref ((ffi:ref *rotation-helper* get-rotation)) invert))
                 (if (or 
                      (not (zerop x))
                      (not (zerop z)))
                     (progn
                       ((ffi:ref rot copy) ((ffi:ref player-model get-rotation)))
                       ((ffi:ref rot slerp) rot
                                            ((ffi:ref *rotation-helper* get-rotation))
                                            (* *rotation-factor* dt))
                       ((ffi:ref player-model set-rotation) rot))))))
      (add-to-update :model-rotate #'update-movement))))

