#lang racket/base

(require (rename-in "private/ffi.rkt"
                    [hid-enumerate hid-enumerate-ffi])
         racket/contract
         racket/list
         (except-in "private/ffi.rkt"
                    hid-enumerate))

(struct hid-device-info (path
                         vendor-id
                         product-id
                         serial-number
                         release-number
                         manufacturer-string
                         product-string
                         usage-page
                         usage
                         interface-number))

;; high-level wrappers

(define (hid-enumerate #:vendor-id [v 0] #:product-id [p 0])
  (define info-list (hid-enumerate-ffi v p))
  (begin0
    (for/list ([info info-list])
      (apply hid-device-info
             ;; necessary to copy C alloc'd strings to racket values
             ;; since we free the values using `hid-free-enumeration`
             (drop-right (map (lambda(e)
                                (cond
                                  [(string? e) (string-copy e)]
                                  [(bytes? e) (bytes->path e)]
                                  [else e]))
                              (hid_device_info->list info))
                         1)))
    (hid-free-enumeration info-list)))

(define (hid-write-full device bstr)
  (hid-write device bstr (bytes-length bstr)))

(define (hid-read-bytes device size)
  (let* ([bstr (make-bytes size)]
         [len  (hid-read device bstr size)])
    (if (= len size)
        bstr
        (subbytes bstr 0 len))))

(define (hid-read-bytes/timeout device size millis)
  (let* ([bstr (make-bytes size)]
         [len  (hid-read-timeout device bstr size millis)])
    (if (= len size)
        bstr
        (subbytes bstr 0 len))))

(provide
 hid-device?
 (struct-out hid-device-info)
 (contract-out
  [hid-init (-> void?)]
  [hid-exit (-> void?)]
  [hid-enumerate (->* ()
                      (#:vendor-id integer? #:product-id integer?)
                      (listof hid-device-info?))]
  [hid-open (-> #:vendor-id integer? #:product-id integer? #:serial-number (or/c string? #f)
                (or/c hid-device? #f))]
  [hid-open-path (-> path? (or/c hid-device? #f))]
  [hid-set-nonblocking (-> hid-device? boolean? void?)]
  [hid-close (-> hid-device? void?)]
  [hid-write (->i ([d hid-device?]
                   [s bytes?]
                   [n (s)
                      (and/c integer?
                             (<=/c (bytes-length s)))])
                  (r integer?))]
  [hid-write-full (-> hid-device? bytes? integer?)]
  [hid-read-timeout (->i ([d hid-device?]
                          [s bytes?]
                          [n (s)
                             (and/c integer?
                                    (<=/c (bytes-length s)))]
                          [t integer?])
                         (r integer?))]
  [hid-read (->i ([d hid-device?]
                  [s bytes?]
                  [n (s)
                     (and/c integer?
                            (<=/c (bytes-length s)))])
                 (r integer?))]
  [hid-read-bytes/timeout (-> hid-device? integer? integer? bytes?)]
  [hid-read-bytes (-> hid-device? integer? bytes?)]
  [hid-get-feature-report (->i ([_ hid-device?]
                                [s bytes?]
                                [n (s)
                                   (and/c integer?
                                          (<=/c (bytes-length s)))])
                               (r integer?))]
  [hid-send-feature-report (->i ([d hid-device?]
                                 [s bytes?]
                                 [n (s)
                                    (and/c integer?
                                           (<=/c (bytes-length s)))])
                                (r integer?))]
  [hid-get-manufacturer-string (-> hid-device? integer? string?)]
  [hid-get-product-string (-> hid-device? integer? string?)]
  [hid-get-serial-number-string (-> hid-device? integer? string?)]
  [hid-get-indexed-string (-> hid-device? integer? integer? string?)]))
