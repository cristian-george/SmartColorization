import cv2
import numpy as np
import torch
from scipy.ndimage.interpolation import zoom
from skimage import color


def lab2rgb_transpose(img_l, img_ab):
    """ INPUTS
            img_l     1xXxX     [0,100]
            img_ab     2xXxX     [-100,100]
        OUTPUTS
            returned value is XxXx3 """
    pred_lab = np.concatenate((img_l, img_ab), axis=0).transpose((1, 2, 0))
    pred_rgb = (np.clip(color.lab2rgb(pred_lab), 0, 1) * 255).astype('uint8')
    return pred_rgb


def rgb2lab_transpose(img_rgb):
    """ INPUTS
            img_rgb XxXx3
        OUTPUTS
            returned value is 3xXxX """
    return color.rgb2lab(img_rgb).transpose((2, 0, 1))


class ColorizeImageBase:
    def __init__(self, xd=256, x_full_res_max=10000):
        self.input_mask_mult = None
        self.input_mask = None
        self.input_ab_mc = None
        self.input_ab = None
        self.img_rgb = None
        self.xd = xd
        self.x_full_res_max = x_full_res_max  # maximum size of maximum dimension
        self.img_l_set = False
        self.net_set = False
        self.img_just_set = False  # this will be true whenever image is just loaded
        self.img_rgb_full_res = None

    def prep_net(self):
        raise Exception("Should be implemented by base class")

    # ***** Image prepping *****
    def load_image(self, input_path):
        # rgb image [CxXdxXd]
        im = cv2.cvtColor(cv2.imread(input_path, 1), cv2.COLOR_BGR2RGB)
        self.img_rgb_full_res = im.copy()
        self._set_img_lab_fullres_()

        im = cv2.resize(im, (self.xd, self.xd))
        self.img_rgb = im.copy()

        self.img_l_set = True

        # convert into lab space
        self._set_img_lab_()
        self._set_img_lab_mc_()

    def set_image(self, input_image):
        self.img_rgb_full_res = input_image.copy()
        self._set_img_lab_fullres_()

        im = cv2.resize(input_image, (self.xd, self.xd))

        self.img_l_set = True

        self.img_rgb = im
        # convert into lab space
        self._set_img_lab_()
        self._set_img_lab_mc_()

    def net_forward(self, input_ab, input_mask):
        # INPUTS
        #     ab         2xXxX     input color patches (non-normalized)
        #     mask     1xXxX    input mask, indicating which points have been provided
        # assumes self.img_l_mc has been set

        if not self.img_l_set:
            print('I need to have an image!')
            return -1
        if not self.net_set:
            print('I need to have a net!')
            return -1

        self.input_ab = input_ab
        self.input_ab_mc = (input_ab - self.ab_mean) / self.ab_norm
        self.input_mask = input_mask
        self.input_mask_mult = input_mask * self.mask_mult
        return 0

    def get_result_psnr(self, result=-1, return_SE_map=False):
        if np.array(result).flatten()[0] == -1:
            cur_result = self.get_img_forward()
        else:
            cur_result = result.copy()
        SE_map = (1. * self.img_rgb - cur_result) ** 2
        cur_MSE = np.mean(SE_map)
        cur_PSNR = 20 * np.log10(255. / np.sqrt(cur_MSE))
        if return_SE_map:
            return cur_PSNR, SE_map
        else:
            return cur_PSNR

    def get_img_forward(self):
        # get image with point estimate
        return self.output_rgb

    def get_img_gray(self):
        # Get black and white image
        return lab2rgb_transpose(self.img_l, np.zeros((2, self.xd, self.xd)))

    def get_img_gray_fullres(self):
        # Get black and white image
        return lab2rgb_transpose(self.img_l_fullres,
                                 np.zeros((2, self.img_l_fullres.shape[1], self.img_l_fullres.shape[2])))

    def get_img_fullres(self):
        # This assumes self.img_l_fullres, self.output_ab are set.
        # Typically, this means that set_image() and net_forward()
        # have been called.
        # bilinear upsample
        zoom_factor = (1, 1. * self.img_l_fullres.shape[1] / self.output_ab.shape[1],
                       1. * self.img_l_fullres.shape[2] / self.output_ab.shape[2])
        output_ab_fullres = zoom(np.array(self.output_ab.tolist()), zoom_factor, order=1)

        return lab2rgb_transpose(self.img_l_fullres, output_ab_fullres)

    def get_input_img_fullres(self):
        zoom_factor = (1, 1. * self.img_l_fullres.shape[1] / self.input_ab.shape[1],
                       1. * self.img_l_fullres.shape[2] / self.input_ab.shape[2])
        input_ab_fullres = zoom(np.array(self.input_ab.tolist()), zoom_factor, order=1)
        return lab2rgb_transpose(self.img_l_fullres, input_ab_fullres)

    def get_input_img(self):
        return lab2rgb_transpose(self.img_l, self.input_ab)

    def get_img_mask(self):
        # Get black and white image
        return lab2rgb_transpose(100. * (1 - self.input_mask), np.zeros((2, self.Xd, self.Xd)))

    def get_img_mask_fullres(self):
        # Get black and white image
        zoom_factor = (1, 1. * self.img_l_fullres.shape[1] / self.input_ab.shape[1],
                       1. * self.img_l_fullres.shape[2] / self.input_ab.shape[2])
        input_mask_fullres = zoom(np.array(self.input_mask.tolist()), zoom_factor, order=0)
        return lab2rgb_transpose(100. * (1 - input_mask_fullres),
                                 np.zeros((2, input_mask_fullres.shape[1], input_mask_fullres.shape[2])))

    def get_sup_img(self):
        return lab2rgb_transpose(50 * self.input_mask, self.input_ab)

    def get_sup_fullres(self):
        zoom_factor = (1, 1. * self.img_l_fullres.shape[1] / self.output_ab.shape[1],
                       1. * self.img_l_fullres.shape[2] / self.output_ab.shape[2])
        input_mask_fullres = zoom(self.input_mask, zoom_factor, order=0)
        input_ab_fullres = zoom(self.input_ab, zoom_factor, order=0)
        return lab2rgb_transpose(50 * input_mask_fullres, input_ab_fullres)

    # ***** Private functions *****
    def _set_img_lab_fullres_(self):
        # adjust full resolution image to be within maximum dimension is within x_full_res_max
        x_full_res = self.img_rgb_full_res.shape[0]
        y_full_res = self.img_rgb_full_res.shape[1]
        if x_full_res > self.x_full_res_max or y_full_res > self.x_full_res_max:
            if x_full_res > y_full_res:
                zoom_factor = 1. * self.x_full_res_max / x_full_res
            else:
                zoom_factor = 1. * self.x_full_res_max / y_full_res
            self.img_rgb_full_res = zoom(self.img_rgb_full_res, (zoom_factor, zoom_factor, 1), order=1)

        self.img_lab_fullres = color.rgb2lab(self.img_rgb_full_res).transpose((2, 0, 1))
        self.img_l_fullres = self.img_lab_fullres[[0], :, :]
        self.img_ab_fullres = self.img_lab_fullres[1:, :, :]

    def _set_img_lab_(self):
        # set self.img_lab from self.im_rgb
        self.img_lab = color.rgb2lab(self.img_rgb).transpose((2, 0, 1))
        self.img_l = self.img_lab[[0], :, :]
        self.img_ab = self.img_lab[1:, :, :]

    def _set_img_lab_mc_(self):
        # set self.img_lab_mc from self.img_lab
        # lab image, mean centered [XxYxX]
        self.img_lab_mc = self.img_lab / np.array((self.l_norm, self.ab_norm, self.ab_norm))[:, np.newaxis,
                                         np.newaxis] - np.array(
            (self.l_mean / self.l_norm, self.ab_mean / self.ab_norm, self.ab_mean / self.ab_norm))[:, np.newaxis,
                                                       np.newaxis]
        self._set_img_l_()

    def _set_img_l_(self):
        self.img_l_mc = self.img_lab_mc[[0], :, :]
        self.img_l_set = True

    def _set_img_ab_(self):
        self.img_ab_mc = self.img_lab_mc[[1, 2], :, :]

    def _set_out_ab_(self):
        self.output_lab = rgb2lab_transpose(self.output_rgb)
        self.output_ab = self.output_lab[1:, :, :]


class ColorizeImageTorch(ColorizeImageBase):
    def __init__(self, Xd=256, maskcent=False):
        ColorizeImageBase.__init__(self, Xd)
        self.net = None
        self.output_rgb = None
        self.l_norm = 1.
        self.ab_norm = 1.
        self.l_mean = 50.
        self.ab_mean = 0.
        self.mask_mult = 1.
        self.mask_cent = .5 if maskcent else 0

        # Load grid properties
        self.pts_in_hull = np.array(np.meshgrid(np.arange(-110, 120, 10), np.arange(-110, 120, 10))).reshape((2, 529)).T

    def prep_net(self, gpu_id=None, path='', dist=False, SIGGRAPHGenerator=None):
        # These errors out when its imported
        print('path = %s' % path)
        print('Model set! dist mode? ', dist)
        if SIGGRAPHGenerator is None:
            raise "No model was specified"
        self.net = SIGGRAPHGenerator(dist=dist)
        state_dict = torch.load(path)
        if hasattr(state_dict, '_metadata'):
            del state_dict._metadata

        # patch InstanceNorm checkpoints prior to 0.4
        for key in list(state_dict.keys()):  # need to copy keys here because we mutate in loop
            self.__patch_instance_norm_state_dict(state_dict, self.net, key.split('.'))
        self.net.load_state_dict(state_dict)
        if gpu_id is not None:
            self.net.cuda()
        self.net.eval()
        self.net_set = True

    def __patch_instance_norm_state_dict(self, state_dict, module, keys, i=0):
        key = keys[i]
        if i + 1 == len(keys):  # at the end, pointing to a parameter/buffer
            if module.__class__.__name__.startswith('InstanceNorm') and \
                    (key == 'running_mean' or key == 'running_var'):
                if getattr(module, key) is None:
                    state_dict.pop('.'.join(keys))
            if module.__class__.__name__.startswith('InstanceNorm') and \
                    (key == 'num_batches_tracked'):
                state_dict.pop('.'.join(keys))
        else:
            self.__patch_instance_norm_state_dict(state_dict, getattr(module, key), keys, i + 1)

    # ***** Call forward *****
    def net_forward(self, input_ab, input_mask):
        # INPUTS
        #     ab         2xXxX     input color patches (non-normalized)
        #     mask     1xXxX    input mask, indicating which points have been provided
        # assumes self.img_l_mc has been set

        if ColorizeImageBase.net_forward(self, input_ab, input_mask) == -1:
            return -1

        # net_input_prepped = np.concatenate((self.img_l_mc, self.input_ab_mc, self.input_mask_mult), axis=0)

        # return prediction
        # self.net.blobs['data_l_ab_mask'].data[...] = net_input_prepped
        # embed()
        output_ab = self.net.forward(self.img_l_mc, self.input_ab_mc, self.input_mask_mult, self.mask_cent)[0, :, :,
                    :].cpu().data.numpy()
        self.output_rgb = lab2rgb_transpose(self.img_l, output_ab)
        # self.output_rgb = lab2rgb_transpose(self.img_l, self.net.blobs[self.pred_ab_layer].data[0, :, :, :])

        self._set_out_ab_()
        return self.output_rgb

    def get_img_forward(self):
        # get image with point estimate
        return self.output_rgb

    def get_img_gray(self):
        # Get black and white image
        return lab2rgb_transpose(self.img_l, np.zeros((2, self.xd, self.xd)))
