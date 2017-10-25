#lang racket/base

(require (for-syntax racket/base
                     syntax/parse)
         ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/define/conventions
         racket/string)

(provide (all-defined-out))

(define-ffi-definer define-hidapi
  (ffi-lib "libhidapi"
           #:fail (lambda ()
                    (ffi-lib "libhidapi-libusb"
                             #:fail (lambda()
                                      (ffi-lib "libhidapi-hidraw"
                                               #:fail (lambda() #f))))))
  #:make-c-id convention:hyphen->underscore
  #:default-make-fail make-not-available)

(define _wchar
  (case (system-type)
    [(windows) (make-ctype _string/utf-16 #f #f)]
    [(unix macosx) (make-ctype _string/ucs-4 #f #f)]))

(define-cstruct _hid_device_info ([path                _bytes]
                                  [vendor-id           _uint16]
                                  [product-id          _uint16]
                                  [serial-number       _wchar]
                                  [release-number      _uint16]
                                  [manufacturer-string _wchar]
                                  [product-string      _wchar]
                                  [usage-page          _uint16]
                                  [usage               _uint16]
                                  [interface-number    _int]
                                  [next                _hid_device_info-pointer/null])
  #:property prop:sequence
  (lambda (i)
    (make-do-sequence
     (lambda ()
       (values (lambda(i) i)
               hid_device_info-next
               i
               (lambda (i) i)
               #f
               (lambda (i v) #t))))))

(define-cpointer-type _hid-device)

(define-syntax-rule (chk-error r src err-expr succ-expr)
  (if (negative? r)
      (error src err-expr)
      succ-expr))

(define-syntax (define-hidapi* stx)
  (syntax-parse stx
    #:literals [_fun -> _int _void]
    [(_ def-id:id ((~seq _fun args_t ... -> [r-id:id (~literal :) _int]
                         (~optional (~seq -> (~or* _void ret:expr))
                                    #:defaults ([ret #'r-id]))))
        (~optional err-str:expr))
     (with-syntax ([err-str (or (attribute err-str) #'"Unsuccessful")]
                   [ret     (or (attribute ret) #'(void))])
       #'(define-hidapi def-id (_fun args_t ...
                                     -> [r-id : _int]
                                     -> (chk-error r-id
                                                   (quote def-id)
                                                   err-str
                                                   ret))))]))

(define (trim-at-nul str)
  (or (for/first ([i (in-range (string-length str))]
                  #:when (char=? (string-ref str i) #\nul))
        (substring str 0 i))
      str))

(define (hid-error* d)
  (let ([err (hid-error d)])
    (if (non-empty-string? err)
        err
        "Unsuccessful")))

(define-hidapi* hid-init (_fun -> [r : _int] -> _void))

(define-hidapi* hid-exit (_fun -> [r : _int] -> _void))

(define-hidapi hid-enumerate (_fun _uint16 _uint16
                                   -> _hid_device_info-pointer))

(define-hidapi hid-free-enumeration (_fun _hid_device_info-pointer -> _void))

(define-hidapi hid-open (_fun (#:vendor-id v #:product-id p #:serial-number s)
                              :: (v : _uint16) (p : _uint16) (s : _wchar)
                              -> _hid-device/null))

(define-hidapi hid-open-path (_fun _path -> _hid-device/null))

(define-hidapi hid-close (_fun _hid-device -> _void))

(define-hidapi hid-error (_fun _hid-device -> _wchar))

(define-hidapi* hid-write
  (_fun [d : _hid-device] _bytes _size -> [r : _int])
  (hid-error* d))

(define-hidapi* hid-read-timeout
  (_fun [d : _hid-device] _bytes _size _int -> [r : _int])
  (hid-error* d))

(define-hidapi* hid-read
  (_fun [d : _hid-device] _bytes _size -> [r : _int])
  (hid-error* d))

(define-hidapi* hid-set-nonblocking
  (_fun [d : _hid-device] _bool -> [r : _int] -> _void)
  (hid-error* d))

(define-hidapi* hid-send-feature-report
  (_fun [d : _hid-device] _bytes _size -> [r : _int])
  (hid-error* d))

(define-hidapi* hid-get-feature-report
  (_fun [d : _hid-device] _bytes _size -> [r : _int])
  (hid-error* d))

(define-hidapi* hid-get-manufacturer-string
  (_fun [d : _hid-device] [s : _wchar = (make-string n)] [n : _size]
        -> [r : _int] -> (trim-at-nul s))
  (hid-error* d))

(define-hidapi* hid-get-product-string
  (_fun [d : _hid-device] [s : _wchar = (make-string n)] [n : _size]
        -> [r : _int] -> (trim-at-nul s))
  (hid-error* d))

(define-hidapi* hid-get-serial-number-string
  (_fun [d : _hid-device] [s : _wchar = (make-string n)] [n : _size]
        -> [r : _int] -> (trim-at-nul s))
  (hid-error* d))

(define-hidapi* hid-get-indexed-string
  (_fun [d : _hid-device] _int [s : _wchar = (make-string n)] [n : _size]
        -> [r : _int] -> (trim-at-nul s))
  (hid-error* d))
