
# distutils: libraries = STD_LIBS
"""
Simple interpolators



"""


import numpy as np

cimport cython
cimport numpy as np

from yt.utilities.lib.fp_utils cimport fclip, fmax, fmin, iclip, imax, imin


@cython.cdivision(True)
@cython.wraparound(False)
@cython.boundscheck(False)
def UnilinearlyInterpolate(np.ndarray[np.float64_t, ndim=1] table,
                           np.ndarray[np.float64_t, ndim=1] x_vals,
                           np.ndarray[np.float64_t, ndim=1] x_bins,
                           np.ndarray[np.int32_t, ndim=1] x_is,
                           np.ndarray[np.float64_t, ndim=1] output):
    cdef double x, xp, xm
    cdef int i, x_i
    for i in range(x_vals.shape[0]):
        x_i = x_is[i]
        x = x_vals[i]
        dx_inv = 1.0 / (x_bins[x_i+1] - x_bins[x_i])
        xp = (x - x_bins[x_i]) * dx_inv
        xm = (x_bins[x_i+1] - x) * dx_inv
        output[i]  = table[x_i  ] * (xm) \
                   + table[x_i+1] * (xp)

@cython.cdivision(True)
@cython.wraparound(False)
@cython.boundscheck(False)
def BilinearlyInterpolate(np.ndarray[np.float64_t, ndim=2] table,
                          np.ndarray[np.float64_t, ndim=1] x_vals,
                          np.ndarray[np.float64_t, ndim=1] y_vals,
                          np.ndarray[np.float64_t, ndim=1] x_bins,
                          np.ndarray[np.float64_t, ndim=1] y_bins,
                          np.ndarray[np.int32_t, ndim=1] x_is,
                          np.ndarray[np.int32_t, ndim=1] y_is,
                          np.ndarray[np.float64_t, ndim=1] output):
    cdef double x, xp, xm
    cdef double y, yp, ym
    cdef double dx_inv, dy_inv
    cdef int i, x_i, y_i
    for i in range(x_vals.shape[0]):
        x_i = x_is[i]
        y_i = y_is[i]
        x = x_vals[i]
        y = y_vals[i]
        dx_inv = 1.0 / (x_bins[x_i+1] - x_bins[x_i])
        dy_inv = 1.0 / (y_bins[y_i+1] - y_bins[y_i])
        xp = (x - x_bins[x_i]) * dx_inv
        yp = (y - y_bins[y_i]) * dy_inv
        xm = (x_bins[x_i+1] - x) * dx_inv
        ym = (y_bins[y_i+1] - y) * dy_inv
        output[i]  = table[x_i  , y_i  ] * (xm*ym) \
                   + table[x_i+1, y_i  ] * (xp*ym) \
                   + table[x_i  , y_i+1] * (xm*yp) \
                   + table[x_i+1, y_i+1] * (xp*yp)

@cython.cdivision(True)
@cython.wraparound(False)
@cython.boundscheck(False)
def TrilinearlyInterpolate(np.ndarray[np.float64_t, ndim=3] table,
                           np.ndarray[np.float64_t, ndim=1] x_vals,
                           np.ndarray[np.float64_t, ndim=1] y_vals,
                           np.ndarray[np.float64_t, ndim=1] z_vals,
                           np.ndarray[np.float64_t, ndim=1] x_bins,
                           np.ndarray[np.float64_t, ndim=1] y_bins,
                           np.ndarray[np.float64_t, ndim=1] z_bins,
                           np.ndarray[np.int_t, ndim=1] x_is,
                           np.ndarray[np.int_t, ndim=1] y_is,
                           np.ndarray[np.int_t, ndim=1] z_is,
                           np.ndarray[np.float64_t, ndim=1] output):
    cdef double x, xp, xm
    cdef double y, yp, ym
    cdef double z, zp, zm
    cdef double dx_inv, dy_inv, dz_inv
    cdef int i, x_i, y_i, z_i
    for i in range(x_vals.shape[0]):
        x_i = x_is[i]
        y_i = y_is[i]
        z_i = z_is[i]
        x = x_vals[i]
        y = y_vals[i]
        z = z_vals[i]
        dx_inv = 1.0 / (x_bins[x_i+1] - x_bins[x_i])
        dy_inv = 1.0 / (y_bins[y_i+1] - y_bins[y_i])
        dz_inv = 1.0 / (z_bins[z_i+1] - z_bins[z_i])
        xp = (x - x_bins[x_i]) * dx_inv
        yp = (y - y_bins[y_i]) * dy_inv
        zp = (z - z_bins[z_i]) * dz_inv
        xm = (x_bins[x_i+1] - x) * dx_inv
        ym = (y_bins[y_i+1] - y) * dy_inv
        zm = (z_bins[z_i+1] - z) * dz_inv
        output[i]  = table[x_i  ,y_i  ,z_i  ] * (xm*ym*zm) \
                   + table[x_i+1,y_i  ,z_i  ] * (xp*ym*zm) \
                   + table[x_i  ,y_i+1,z_i  ] * (xm*yp*zm) \
                   + table[x_i  ,y_i  ,z_i+1] * (xm*ym*zp) \
                   + table[x_i+1,y_i  ,z_i+1] * (xp*ym*zp) \
                   + table[x_i  ,y_i+1,z_i+1] * (xm*yp*zp) \
                   + table[x_i+1,y_i+1,z_i  ] * (xp*yp*zm) \
                   + table[x_i+1,y_i+1,z_i+1] * (xp*yp*zp)

@cython.cdivision(True)
@cython.wraparound(False)
@cython.boundscheck(False)
def ghost_zone_interpolate(int rf,
                           np.ndarray[np.float64_t, ndim=3] input_field,
                           np.ndarray[np.float64_t, ndim=1] input_left,
                           np.ndarray[np.float64_t, ndim=3] output_field,
                           np.ndarray[np.float64_t, ndim=1] output_left):
    cdef int oi, oj, ok
    cdef int ii, ij, ik
    cdef np.float64_t xp, xm, yp, ym, zp, zm, temp
    cdef np.float64_t ods[3]
    cdef np.float64_t ids[3]
    cdef np.float64_t iids[3]
    cdef np.float64_t opos[3]
    cdef np.float64_t ropos[3]
    cdef int i
    for i in range(3):
        temp = input_left[i] + (rf * (input_field.shape[i] - 1))
        ids[i] = (temp - input_left[i])/(input_field.shape[i]-1)
        temp = output_left[i] + output_field.shape[i] - 1
        ods[i] = (temp - output_left[i])/(output_field.shape[i]-1)
        iids[i] = 1.0/ids[i]
    opos[0] = output_left[0]
    for oi in range(output_field.shape[0]):
        ropos[0] = ((opos[0] - input_left[0]) * iids[0])
        ii = iclip(<int> ropos[0], 0, input_field.shape[0] - 2)
        xp = ropos[0] - ii
        xm = 1.0 - xp
        opos[1] = output_left[1]
        for oj in range(output_field.shape[1]):
            ropos[1] = ((opos[1] - input_left[1]) * iids[1])
            ij = iclip(<int> ropos[1], 0, input_field.shape[1] - 2)
            yp = ropos[1] - ij
            ym = 1.0 - yp
            opos[2] = output_left[2]
            for ok in range(output_field.shape[2]):
                ropos[2] = ((opos[2] - input_left[2]) * iids[2])
                ik = iclip(<int> ropos[2], 0, input_field.shape[2] - 2)
                zp = ropos[2] - ik
                zm = 1.0 - zp
                output_field[oi,oj,ok] = \
                     input_field[ii  ,ij  ,ik  ] * (xm*ym*zm) \
                   + input_field[ii+1,ij  ,ik  ] * (xp*ym*zm) \
                   + input_field[ii  ,ij+1,ik  ] * (xm*yp*zm) \
                   + input_field[ii  ,ij  ,ik+1] * (xm*ym*zp) \
                   + input_field[ii+1,ij  ,ik+1] * (xp*ym*zp) \
                   + input_field[ii  ,ij+1,ik+1] * (xm*yp*zp) \
                   + input_field[ii+1,ij+1,ik  ] * (xp*yp*zm) \
                   + input_field[ii+1,ij+1,ik+1] * (xp*yp*zp)
                opos[2] += ods[2]
            opos[1] += ods[1]
        opos[0] += ods[0]

@cython.cdivision(True)
@cython.wraparound(False)
@cython.boundscheck(False)
def fix_nonperiodic(np.ndarray[np.float64_t, ndim=3] field,
                    np.ndarray[np.int_t,     ndim=1] lo_offset,
                    np.ndarray[np.int_t,     ndim=1] hi_offset):
    cdef int i, j, k
    cdef int ii, ij, ik
    cdef int nx, ny, nz
    cdef int lx, ly, lz
    cdef int hx, hy, hz
    cdef np.float64_t xp, xm, yp, ym, zp, zm
    cdef np.float64_t qp, qm

    nx = field.shape[0]
    ny = field.shape[1]
    nz = field.shape[2]
    lx = lo_offset[0]
    ly = lo_offset[1]
    lz = lo_offset[2]
    hx = hi_offset[0]
    hy = hi_offset[1]
    hz = hi_offset[2]

    # Fix boundaries in the x direction
    if lx > 0 or hx > 0:
        for j in range(lo_offset[1], ny-hi_offset[1]):
            for k in range(lo_offset[2], field.shape[2]-hi_offset[2]):
                # Fix xlo
                qm = field[lx,   j, k]
                qp = field[lx+1, j, k]
                for i in range(lx):
                    xp = float(i - lx)
                    xm = 1.0 - xp
                    field[i, j, k] = xm*qm + xp*qp
                # Fix xhi
                qm = field[nx-hx-2, j, k]
                qp = field[nx-hx-1, j, k]
                for i in range(nx-hx, nx):
                    # print('in xhi fix')
                    xp = float(i - (nx-hx-1))
                    xm = 1.0 - xp
                    field[i, j, k] = xm*qm + xp*qp
