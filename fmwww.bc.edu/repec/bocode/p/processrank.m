%processrank
%this procedure scrapes and stores country ranks for month m in year y
%
%This version: 7 August 2011 by Richard Tol

strcat('20',year(y,1),year(y,2),'-',month(m,1),month(m,2))
address=strcat(address1,year(y,1),year(y,2),month(m,1),month(m,2),address2);
%s is a long array of characters
s = urlread(address);
%columns separated by <TD>; columnsep is an array of indices of s
columnsep = strfind(s, '<TD>');
%columns separated by </TD>; columnsep is an array of indices of s
columnsep2 = strfind(s, '</TD>');
for c=1:ncountries,
    %country is an index of s
    country = strfind(s, cell2mat(region(c)));
    if length(country)>0,
       %remove all indices before country
       mask = find(columnsep>country(1),nindic);
       mask2= find(columnsep2>country(1),nindic);
       %grab is a short array of characters
       grab=s(columnsep(mask(1))+shift0:columnsep(mask(2))-tfihs0);
       %convert to double and store
       rank(index(y,m),c,1)=str2double(grab);
       %score(:,:,1) is different because always in the same font
       lc=1; %local counter
       for i=2:nindic,
           if indic(i) < index(y,m),
              lc = lc+1; 
              %grab is a short array of characters
              grab=s(columnsep(mask(lc))+shift:columnsep2(mask2(lc)+1)-tfihs);
              %convert to double and store
              rank(index(y,m),c,i)=str2double(grab);
           end
       end       
    end
end
