% RANGE = pgmWrite(MTX, FILENAME, RANGE, TYPE, DATATYPE)
%
% Write a MatLab matrix to a pgm (graylevel image) file.
% This format is accessible from the XV image browsing utility.
%
% RANGE (optional) is a 2-vector specifying the values that map to
% black and white, respectively.  Passing a value of 'auto' (default)
% sets RANGE=[min,max] (as in MatLab's imagesc).  'auto2' sets
% RANGE=[mean-2*stdev, mean+2*stdev].  'auto3' sets
% RANGE=[p1-(p2-p1)/8, p2+(p2-p1)/8], where p1 is the 10th percentile
% value of the sorted MATRIX samples, and p2 is the 90th percentile
% value.
%
% TYPE (optional) should be 'raw' or 'ascii'.  Defaults to 'raw'.
% DATATYPE (optional) should be 'uchar', 'float', or 'short'.

% Hany Farid,  Spring '96.  Modified by Eero Simoncelli, 6/96.

function range = pgmWrite(mtx, fname, range, type, datatype );

[fid,msg] = fopen( fname, 'w' );

if (fid == -1)
  error(msg);
end

%------------------------------------------------------------
%% optional ARGS:

if (exist('range') ~= 1)
  range = 'auto';
end

if (exist('type') ~= 1)
  type = 'raw';
end

if (exist('datatype') ~= 1)
  datatype = 'uchar';
end
%------------------------------------------------------------

%% Automatic range calculation:
if (strcmp(range,'auto1') | strcmp(range,'auto'))
  [mn,mx] = range2(mtx);
  range = [mn,mx];

elseif strcmp(range,'auto2')
  stdev = sqrt(var2(mtx));
  av = mean2(mtx);
  range = [av-2*stdev,av+2*stdev]; 	% MAGIC NUMBER: 2 stdevs

elseif strcmp(range, 'auto3')
  percentile = 0.1;			% MAGIC NUMBER: 0<p<0.5
  [N,X] = histo(mtx);
  binsz = X(2)-X(1);
  N = N+1e-10;  % Ensure cumsum will be monotonic for call to interp1
  cumN = [0, cumsum(N)]/sum(N);
  cumX = [X(1)-binsz, X] + (binsz/2);
  ctrRange = interp1(cumN,cumX, [percentile, 1-percentile]);
  range = mean(ctrRange) + (ctrRange-mean(ctrRange))/(1-2*percentile);

elseif isstr(range)
  error(sprintf('Bad RANGE argument: %s',range))

end

if isempty(range)
  range = [0 0];
end
if ((range(2) - range(1)) <= eps)
  range(1) = range(1) - 0.5;
  range(2) = range(2) + 0.5;
end


%%% First line contains ID string:
%%% "P1" = ascii bitmap, "P2" = ascii greymap,
%%% "P3" = ascii pixmap, "P4" = raw bitmap,
%%% "P5" = raw greymap, "P6" = raw pixmap
%%% "P7" = raw float greymap, "P9" = raw short greymap

if strcmp(type,'raw')
  if strcmp(datatype,'uchar')
  	fprintf(fid,'P5\n');
  	format = 5;
  elseif strcmp(datatype,'float')
  	fprintf(fid,'P7\n');
  	format = 7;
  elseif strcmp(datatype,'short')
  	fprintf(fid,'P9\n');
  	format = 9;
  else
	error(sprintf('PGMWRITE: Invalid datatype: %s',datatype));
  end
elseif strcmp(type,'ascii')
  fprintf(fid,'P2\n');
  format = 2;
else
  error(sprintf('PGMWRITE: Bad type argument: %s',type));
end

fprintf(fid,'# MatLab PGMWRITE file, saved %s\n',date);

%%% dimensions
fprintf(fid,'%d %d\n',size(mtx,2),size(mtx,1));

%%% Maximum pixel value
fprintf(fid,'255\n');


%% MatLab's "fprintf" floors when writing floats, so we compute
%% (mtx-r1)*255/(r2-r1)+0.5
if ~strcmp(datatype, 'float')
  mult = (255 / (range(2)-range(1)));
  mtx = (mult * mtx) + (0.5 - mult * range(1));
  mtx = max(-0.5+eps,min(255.5-eps,mtx));
end

if type == 2
  if strcmp(datatype, 'float')
    count = fprintf(fid,'%d ',mtx');
  else
    count = fprintf(fid,'%d ',mtx');
  end
else
  count = fwrite(fid,mtx',datatype);
end

fclose(fid);

if (count ~= size(mtx,1)*size(mtx,2))
  fprintf(1,'Warning: File output terminated early!');
end

%%% TEST:
% foo = 257*rand(100)-1;
% pgmWrite(foo,'foo.pgm',[0 255]);
% foo2=pgmRead('foo.pgm');
% size(find((foo2-round(foo))~=0))
% foo(find((foo2-round(foo))~=0))
