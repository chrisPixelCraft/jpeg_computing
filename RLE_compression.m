function [compressed_vector, AC_dict, DC_dict] = RLE_compression(entropy_mat, blocksize)
    disp("RLE coding...");
    [DC, AC] = separate_dc_ac(entropy_mat, blocksize);
    [VLC_AC, VLI_AC] = rle_encode_ac(AC, blocksize);
    [VLC_DC, VLI_DC] = rle_encode_dc(DC);
    disp("DONE");
    
    disp("huffman coding...");
    [huff_AC, AC_dict] = huffman_cod(transpose(VLC_AC));
    [huff_DC, DC_dict] = huffman_cod(transpose(VLC_DC));
    disp("DONE");

    compressed_vector = [huff_AC; VLI_AC; huff_DC; VLI_DC];
    %convert to logical
    compressed_vector = compressed_vector == 1;
end

function [DC, AC] = separate_dc_ac(entropy_mat, blocksize)
    [dim1, dim2] = size(entropy_mat);    
    %logical indexing
    idx = false(blocksize);
    idx(1, 1) = 1;
    DC = zeros(0, 1);
    AC = zeros(0, 1);
    for i = 1: blocksize: dim1
        for j = 1: blocksize: dim2
            tile = entropy_mat(i: i+blocksize-1, j: j+blocksize-1);
            DC = [DC;tile(idx)];
            AC = [AC;tile(~idx)];
            %straigtened out automatically, the lowest frequencies in a
            %block should come first
        end
    end


    %DC = transpose(entropy_mat(idx));
    %AC = transpose(entropy_mat(~idx));
end

function [VLC, VLI] = rle_encode_dc(data)
    % Run-Length Encoding (RLE) compression algorithm
    % Input: data - string or array to be compressed
    % Output: encoded_data - cell array of symbols

    %symbol-type I: (bit width of non-zero value)-> to be huffmancoded(VLC) 
    %the output VLC will be a cell array containing symbols

    %symbol-type II: (actual binary sequence of variable length that
    %succeeds the zeros) --> transmitted as-is (VLI)
    %the output VLI will be a binary sequence with no boundaries between
    %numbers (bit width is stored in VLC)

    %for other nuances, consult JPEG baseline model standards
    

    % Initialize variables
    VLC = cell(0, 1);
    VLI = false(0, 1);
    prev = 0;

    if isempty(data)
        return;
    end
   
    % Iterate through the input data
    for i = 1:length(data)
        diff = data(i) - prev;
        prev = data(i);
        if diff == 0
            VLC = [VLC; {0}];
        else
            sign_bit = (sign(diff) == -1);
            real_len = length(dec2bin(abs(diff)));
            offset = power(2, real_len-1);
            bin = dec2bin(abs(diff) - offset, real_len);
            bin = transpose(bin == '1');
            bin(1, 1) = sign_bit;
            VLI = [VLI; bin];%append the VLI code
            VLC = [VLC; {real_len}];
        end
    end
end

function [VLC, VLI] = rle_encode_ac(data, blocksize)
    % Run-Length Encoding (RLE) compression algorithm
    % Input: data - string or array to be compressed
    % Output: encoded_data - cell array of symbols

    %symbol-type I: (run length of previous 0, bit width of non-zero value)
    %--> to be huffmancoded(VLC) 
    %the output VLC will be a cell array containing symbols

    %symbol-type II: (actual binary sequence of variable length of the value 
    %that succeeds the zeros) --> transmitted as-is (VLI)
    %the output VLI will be a binary sequence with no boundaries between
    %numbers (bit width is stored in VLC)

    %for other nuances, consult JPEG baseline model standards


    
    % Initialize variables
    ac_block_len = blocksize*blocksize-1;%for 8x8 blocks, there are 63 ac components
    count = 0;
    max_len = length(data) + length(data)/ac_block_len;
    VLC = cell(max_len, 1);
    %VLC = cell(0, 1);
    idx = 0;
    VLI = false(0, 1);

    if isempty(data)
        return;
    end

    % Iterate through the input data
    for i = 1:length(data)
        if data(i) == 0
            if(count == 15 || mod(i, ac_block_len) == 0)
                idx = idx + 1;
                VLC(idx, 1) = {[count, 0]};%append Extension symbol
                %VLC = [VLC; {[count, 0]}];
                count = 0;
            else 
                count = count + 1;
            end
        else
            sign_bit = (sign(data(i)) == -1);
            real_len = length(dec2bin(abs(data(i))));
            offset = power(2, real_len-1);
            bin = dec2bin(abs(data(i)) - offset, real_len);
            bin = transpose(bin == '1');
            bin(1, 1) = sign_bit;
            VLI = [VLI; bin];%append the VLI code
            idx = idx + 1;
            VLC(idx, 1) = {[count, real_len]};
            %VLC = [VLC; {[count, real_len]}];
            count = 0;
        end
        if (mod(i, ac_block_len) == 0)
            idx = idx + 1;
            VLC(idx, 1) = {[0, 0]};
            %VLC = [VLC; {[0, 0]}];
        end
    end
    VLC = VLC(1: idx, 1);%truncate the excess length
end