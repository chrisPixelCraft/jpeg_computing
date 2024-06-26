function [ output_image, compressed_vector, ratio ] = jpeg_computing( input_image, q)
% Author: Boris Knyazev, bknyazev@bmstu.ru
%---------------------------
% This is a function to test a JPEG-based encoding/decoding algorithm and look at the picture
% and a respective compression ratio
% It is based on the lectures from Coursera.org and intended for studying
% purposes only
%---------------------------
% input_image is an image [colored] matrix
% q is a quality (from 1 to 100 percent), 100 - the best quality and low
% compression, too little values (less than 10) are not guaranteed to work
% output_image is a compressed image [colored] matrix
% compressed_vector is an output binary vector representing the compressed
% image
% ratio is a compression ratio (the more ratio the more data are compressed)
%---------------------------
% define init values
n = 8; % size of blocks
dim1 = size(input_image,1); % image width
dim2 = size(input_image,2); % image height
dim3 = size(input_image,3); % number of channels
if (dim3 > 1)
    ycbcrmap = rgb2ycbcr(im2double(input_image)); % mapping, need double for DCT
else
    ycbcrmap = im2double(input_image);
end
%==============================================
%Implement Downsample of Chromatic Components







% here you can (should) also paste downsampling of chroma components
output_image = zeros(size(input_image), 'double');

[qY, qC] = get_quantization(q); % get quantization matrices
T = dctmtx(n); % DCT matrix
scale = 255; % need because DCT values of YCbCr are too small to be quantized


% Block processing functions
dct = @(block_struct) T * block_struct.data * T';
invdct = @(block_struct) T' * block_struct.data * T;
quantY = @(block_struct) round( block_struct.data./qY);
dequantY = @(block_struct) block_struct.data.*qY;
quantC = @(block_struct) round( block_struct.data./qC);
dequantC = @(block_struct) block_struct.data.*qC;
zig_zag_proc = @(block_struct) zig_zag_cod(block_struct.data, n);

%initialize compressed vector
compressed_vector = false(0, 1);
%---------------------------
for ch=1:dim3
    % encoding ---------------------------
    channel = ycbcrmap(:,:,ch); % get channel
    % compute scaled forward DCT
    channel_dct = blockproc(channel, [n n], dct, 'PadPartialBlocks', true).*scale; 
    % quantization
    if (ch == 1)
        channel_q = blockproc(channel_dct,[n n], quantY);  % quantization for luma
    else
        channel_q = blockproc(channel_dct,[n n], quantC);  % quantization for colors
    end
    zig_zag_out = blockproc(channel_q,[n n], zig_zag_proc); % compute zig_zag code for the whole channel
    save("zig_zag_mat.mat", "zig_zag_out");%for testing purposes
        

    %------------------------------------------------------
    %RLE COMPRESSION
    %------------------------------------------------------
    [comp, AC_dict, DC_dict] = RLE_compression(zig_zag_out, n);
    %HOW TO CACULATE THE SIZE (in bits) OF DICT?


    compressed_vector = cat(1, compressed_vector, comp); % add to output

    % dequantization
    if (ch == 1)
        channel_q = blockproc(channel_q,[n n], dequantY);
    else
        channel_q = blockproc(channel_q,[n n], dequantC);
    end
    output_data = blockproc(channel_q./scale,[n n],invdct); % inverse DCT, scale back
    output_image(:,:,ch) = output_data(1:dim1, 1:dim2); % set output
end
%---------------------------

if (dim3 > 1)
    output_image = im2uint8(ycbcr2rgb(output_image)); % back to rgb uint8
else
    output_image = im2uint8(output_image); % back to rgb uint8
end
% compute compression ratio
% compressed_vector is binary, input image has one byte per pixel
ratio = dim1 * dim2 * dim3 *8 / (length(compressed_vector)); % size of huffman dicitonary  is missed
subplot(1,2,1), imshow(input_image) % show results 
subplot(1,2,2), imshow(output_image) % show results 
end 




% function [zig_zag_code] = get_zig_zag (zig_zag_raw_matrix, n, dim1, dim2)
% % go by tiles in loops to extract shortened zig_zag codes (without
% % zeros on the end)
% step = n-1; % poor stuff for zig_zag coding iterations, should be avoided
% tile = zig_zag_raw_matrix(1:1+step, 1:1+step);
% zig_zag_code = tile(1:find(tile(:),1,'last'));
% for i=step+2:step+1:dim1-step
%     for j=step+2:step+1:dim2-step
%         tile = zig_zag_raw_matrix(i:i+step, j:j+step);
%         zig_zag_code = cat(2, zig_zag_code, tile(1:find(tile(:),1,'last')));
%     end
% end
% end




