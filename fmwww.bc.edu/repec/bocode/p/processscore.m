%processscore
%this procedure scrapes and stores country metrics for month m in year y
%
%This version: 7 August 2011 by Richard Tol

address=strcat(address1,year(y,1),year(y,2),month(m,1),month(m,2),address3,cell2mat(indicname(1)),address4);
%s is a long array of characters
s = urlread(address);
%columns separated by <TD>; columnsep is an array of indices of s
columnsep = strfind(s, '<TD>');
%columns separated by </TD>; columnsep is an array of indices of s
columnsep2 = strfind(s, '</TR>');
for c=1:ncountries,
    %country is an index of s
    country = strfind(s, cell2mat(region(c)));
    if length(country)>0,
       %remove all indices before country
       mask = find(columnsep>country(1),2);
       mask2= find(columnsep2>country(1),1);
       %grab is a short array of characters
       grab=s(columnsep(mask(1))+shift0:columnsep(mask(2))-tfihs0);
       %convert to double and store
       score(index(y,m),c,2)=str2double(grab);
       grab=s(columnsep(mask(2))+shift0:columnsep2(mask2(1))-1);
       score(index(y,m),c,1)=str2double(grab);
    end
end

for i=3:nindic,
    if indic(i) < index(y,m),
       address=strcat(address1,year(y,1),year(y,2),month(m,1),month(m,2),address3,cell2mat(indicname(i)),address4); 
       s = urlread(address);
       columnsep = strfind(s, '<TD>');
        for c=1:ncountries,
            country = strfind(s, cell2mat(region(c)));
            if length(country)>0,
               mask = find(columnsep>country(1),2);
               grab=s(columnsep(mask(1))+shift0:columnsep(mask(2))-tfihs0);
               score(index(y,m),c,i)=str2double(grab);
            end
        end
    end
end